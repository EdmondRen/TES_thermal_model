import importlib.util
import re
from pathlib import Path

import numpy as np
from scipy.io import loadmat


_CONNECT_RE = re.compile(r"\bconnect\s*\(\s*([^,]+?)\s*,\s*([^)]+?)\s*\)", re.DOTALL)
_COMPONENT_RE = re.compile(
    r"\b(?P<type>(?:[\w]+\.)*(?:ThermlConductanceN|HeatCapacitorPoly|TES2|FixedTemperature))\s+"
    r"(?P<name>[A-Za-z_]\w*)\b"
)


class _UnionFind:
    def __init__(self):
        self.parent = {}

    def find(self, item):
        if item not in self.parent:
            self.parent[item] = item
            return item

        root = item
        while self.parent[root] != root:
            root = self.parent[root]

        while self.parent[item] != item:
            item, self.parent[item] = self.parent[item], root

        return root

    def union(self, left, right):
        left_root = self.find(left)
        right_root = self.find(right)

        if left_root != right_root:
            self.parent[right_root] = left_root


def _strip_modelica_comments(text):
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
    return re.sub(r"//.*", "", text)


def _connector_name(connector):
    return re.sub(r"\s+", "", connector)


def _parse_indexed_name(name, prefix):
    match = re.fullmatch(rf"{re.escape(prefix)}([1-9]\d*)", name)
    return int(match.group(1)) if match else None


def parse_thermal_conductance_connections(modelica_file):
    """
    Parse a Modelica model and return heat-capacity endpoints for each g*.

    The parser expects the repository naming convention:
      - nonlinear thermal conductances are named g1, g2, ...
      - heat capacities are named c1, c2, ...

    Each returned value is a tuple of HeatCapacitorPoly/TES2 indices connected
    to (port_a, port_b). Connections to fixedTemperature.port are reported as
    index 0.
    """

    text = Path(modelica_file).read_text()
    text = _strip_modelica_comments(text)

    conductances = {}
    capacities = {}
    fixed_temperatures = set()

    for match in _COMPONENT_RE.finditer(text):
        component_type = match.group("type").split(".")[-1]
        name = match.group("name")

        if component_type == "ThermlConductanceN":
            index = _parse_indexed_name(name, "g")
            if index is not None:
                conductances[name] = index

        elif component_type in ("HeatCapacitorPoly", "TES2"):
            index = _parse_indexed_name(name, "c")
            if index is not None:
                capacities[name] = index

        elif component_type == "FixedTemperature":
            fixed_temperatures.add(name)

    uf = _UnionFind()

    for left, right in _CONNECT_RE.findall(text):
        uf.union(_connector_name(left), _connector_name(right))

    node_endpoints = {}

    for capacity_name, index in capacities.items():
        for port in ("port", "heatPort"):
            connector = f"{capacity_name}.{port}"
            root = uf.find(connector)
            node_endpoints.setdefault(root, set()).add(index)

    for fixed_name in fixed_temperatures:
        connector = f"{fixed_name}.port"
        root = uf.find(connector)
        node_endpoints.setdefault(root, set()).add(0)

    def resolve_endpoint(conductance_name, port):
        connector = f"{conductance_name}.{port}"
        root = uf.find(connector)
        endpoints = node_endpoints.get(root, set())

        if not endpoints:
            raise ValueError(
                f"Cannot resolve {connector} to a c* port or fixedTemperature.port"
            )

        if len(endpoints) > 1:
            endpoint_list = ", ".join(str(endpoint) for endpoint in sorted(endpoints))
            raise ValueError(f"Ambiguous endpoints for {connector}: {endpoint_list}")

        return next(iter(endpoints))

    return {
        index: (
            resolve_endpoint(conductance_name, "port_a"),
            resolve_endpoint(conductance_name, "port_b"),
        )
        for conductance_name, index in sorted(
            conductances.items(), key=lambda item: item[1]
        )
    }


def _load_linearized_model(linearized_model):
    """
    Return the tuple produced by an OpenModelica linearized_model() function.

    linearized_model may be the tuple itself, a callable, an imported module, or
    a path to a Python file containing linearized_model().
    """

    if isinstance(linearized_model, tuple):
        return linearized_model

    if callable(linearized_model):
        return linearized_model()

    if hasattr(linearized_model, "linearized_model"):
        return linearized_model.linearized_model()

    if isinstance(linearized_model, (str, Path)):
        path = Path(linearized_model)
        spec = importlib.util.spec_from_file_location(path.stem, path)
        if spec is None or spec.loader is None:
            raise ValueError(f"Cannot import linearized model from {path}")

        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)

        if not hasattr(module, "linearized_model"):
            raise ValueError(f"{path} does not define linearized_model()")

        return module.linearized_model()

    raise TypeError(
        "linearized_model must be a tuple, callable, module, or Python file path"
    )


def _linearized_state_permutation(state_vars):
    state_vars = list(state_vars)
    state_positions = {name: i for i, name in enumerate(state_vars)}

    if len(state_positions) != len(state_vars):
        duplicates = sorted(
            {name for name in state_vars if state_vars.count(name) > 1}
        )
        raise ValueError(f"Duplicate state variable names: {duplicates}")

    required_states = ("CL_v", "L_i")
    missing_states = [
        name for name in required_states
        if name not in state_positions
    ]

    if missing_states:
        raise ValueError(f"Missing required state variables: {missing_states}")

    c_states = []
    unknown_states = []

    for name in state_vars:
        if name in required_states:
            continue

        match = re.fullmatch(r"c([1-9]\d*)_T", name)
        if match is None:
            unknown_states.append(name)
        else:
            c_states.append((int(match.group(1)), name))

    if unknown_states:
        raise ValueError(f"Unknown state variable names: {unknown_states}")

    c_indices = [index for index, _ in c_states]
    duplicate_indices = sorted(
        {index for index in c_indices if c_indices.count(index) > 1}
    )

    if duplicate_indices:
        raise ValueError(f"Duplicate c*_T state indices: {duplicate_indices}")

    sorted_state_vars = list(required_states) + [
        name for _, name in sorted(c_states)
    ]

    return [state_positions[name] for name in sorted_state_vars], sorted_state_vars


def _identity_permutation(variable_names, expected_count, axis_name):
    variable_names = list(variable_names)

    if len(variable_names) != expected_count:
        raise ValueError(
            f"Expected {expected_count} {axis_name} variables, "
            f"got {len(variable_names)}"
        )

    return list(range(expected_count)), variable_names


def load_linearized_model(linearized_model):
    """
    Normalize an OpenModelica Python linearized_model() result.

    Returns a dictionary with NumPy arrays for x0, u0, A, B, C, and D plus the
    state, input, and output variable name lists.
    """

    (
        n,
        m,
        p,
        x0,
        u0,
        A,
        B,
        C,
        D,
        state_vars,
        input_vars,
        output_vars,
    ) = _load_linearized_model(linearized_model)

    A = np.asarray(A, dtype=float).reshape((n, n))
    x0 = np.asarray(x0, dtype=float).reshape((n,))
    u0 = np.asarray(u0, dtype=float).reshape((m,)) if m else np.empty((0,))

    B = np.asarray(B, dtype=float).reshape((n, m)) if m else np.empty((n, 0))
    C = np.asarray(C, dtype=float).reshape((p, n)) if p else np.empty((0, n))
    D = np.asarray(D, dtype=float).reshape((p, m)) if p and m else np.empty((p, m))

    state_permutation, state_vars = _linearized_state_permutation(state_vars)
    input_permutation, input_vars = _identity_permutation(input_vars, m, "input")
    output_permutation, output_vars = _identity_permutation(output_vars, p, "output")

    x0 = x0[state_permutation]
    u0 = u0[input_permutation]
    A = A[np.ix_(state_permutation, state_permutation)]
    B = B[np.ix_(state_permutation, input_permutation)]
    C = C[np.ix_(output_permutation, state_permutation)]
    D = D[np.ix_(output_permutation, input_permutation)]

    return {
        "n": n,
        "m": m,
        "p": p,
        "x0": x0,
        "u0": u0,
        "A": A,
        "B": B,
        "C": C,
        "D": D,
        "stateVars": list(state_vars),
        "inputVars": list(input_vars),
        "outputVars": list(output_vars),
    }


class TESModel:
    def __init__(self, linearized_model, config, f_min = 1, f_max = 100e3, points = 1000):
        """
        config: dict
            Dictionary containing the configuration parameters for the analysis. List of parameters:
            "L": Inductance value of the TES circuit in Henrys (H).
            "RL": Resistance value of the TES circuit in Ohms (Ω).
        """
        
        self.config = config
        self.model = load_linearized_model(linearized_model)
        self.frequencies = np.logspace(np.log10(f_min), np.log10(f_max), points)
        self.w = 2j*np.pi*self.frequencies

        
        
    def get_impedance(self):
        """
        Solver for complex impedance
        ---
        ---
        Z_model: array of complex float
            complex impedance
        """
        A = self.model["A"]
        
        Z_model = []
        for iw in self.w:
            N = A - iw*np.eye(A.shape[0]) # Compute eigenvectors
            N_inv = np.linalg.inv(N) # Compute inverse of the eigenvectors      
            phi0 = np.zeros_like(self.model["x0"])  # Pulse to Absorber
            phi0[0] = 1/self.config["L"]

            res = N_inv.dot(phi0) #Dot the inverse of the eigenvector with the input pulse to get our coefficients

            Z_model.append(-1./res[0]-iw*self.config["L"])
        Z_model = np.array(Z_model)
        return Z_model


def load(filename):
    """
    # File format
    # https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/technical_details.html
    """
    
    mat = loadmat(filename, chars_as_strings=False)

    name_matrix = mat["name"]
    data_info = mat["dataInfo"]

    def decode_strings(char_matrix, n_variables):
        """
        Decode OpenModelica character matrix.

        Handles scipy returning either:
          - Unicode/string characters
          - integer character codes

        Also handles either matrix orientation.
        """

        # Determine which axis represents variables
        if char_matrix.shape[1] == n_variables:
            columns_are_variables = True
        elif char_matrix.shape[0] == n_variables:
            columns_are_variables = False
        else:
            raise ValueError(
                f"Cannot determine name matrix orientation.\n"
                f"name shape: {char_matrix.shape}\n"
                f"number of variables: {n_variables}"
            )

        names = []

        for i in range(n_variables):
            chars = (
                char_matrix[:, i]
                if columns_are_variables
                else char_matrix[i, :]
            )

            chars = np.asarray(chars).ravel()

            if chars.dtype.kind in ("U", "S"):
                # scipy already decoded characters
                parts = []

                for c in chars:
                    if isinstance(c, bytes):
                        c = c.decode("utf-8", errors="ignore")
                    else:
                        c = str(c)

                    if c != "\x00":
                        parts.append(c)

                name = "".join(parts).rstrip()

            else:
                # Numeric character codes
                name = "".join(
                    chr(int(c))
                    for c in chars
                    if int(c) != 0
                ).rstrip()

            names.append(name)

        return names

    n_variables = data_info.shape[1]
    names = decode_strings(name_matrix, n_variables)

    data_1 = mat.get("data_1")
    data_2 = mat.get("data_2")

    variables = {}

    for i, name in enumerate(names):

        data_set = int(data_info[0, i])
        index = int(data_info[1, i])

        # Negative index indicates a negated alias
        sign = -1.0 if index < 0 else 1.0

        # MATLAB indices start at 1
        row = abs(index) - 1

        if data_set == 1 and data_1 is not None:
            values = sign * data_1[row, :]

        elif data_set == 2 and data_2 is not None:
            values = sign * data_2[row, :]

        else:
            continue

        variables[name] = np.asarray(values).squeeze()

    time = np.asarray(data_2[0, :]).squeeze()

    return time, variables




def mod_svg(filename, output_filename, data, system_name="System_LMO", width=900, display=True):
    with open(filename, 'r') as file:
        content = file.read()

    # Replace the target text
    # updated_content = content.replace(search_text, replace_text)
    
    ## Define for each system name the corresponding replacement rules
    if system_name == "System_LMO":
        for i in range(1, 14+1):
            search_text = f">K=K{i} <"
            replace_text = f">G={data[f'g{i}.G'][-1]:.3g} <"
            content = content.replace(search_text, replace_text)
        
        for i in range(1, 9+1):
            search_text = f">m=m{i} <"
            replace_text = f">C={data[f'c{i}.C'][-1]:.3g} <"
            content = content.replace(search_text, replace_text)
            
        search_text = f">  m=TES_m <"
        replace_text = f">  C={data[f'c10.C'][-1]:.3g} <"
        content = content.replace(search_text, replace_text)
        
        search_text = f">  Tc=TES_Tc <"
        replace_text = f">  T={data[f'c10.T'][-1]:.3g} <"
        content = content.replace(search_text, replace_text)
        
        

    # Open the file in write mode to overwrite it
    with open(output_filename, "w") as file:
        file.write(content)
        

    if display:
        from IPython.display import HTML
        import time

        return HTML(
            f'<img src="{output_filename}?t={time.time()}" '
            f'width="{width}" '
            'style="background-color: #ffffff; padding: 16px; border-radius: 8px;">'
        )
