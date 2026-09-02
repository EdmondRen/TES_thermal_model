import numpy as np
from scipy.io import loadmat


def load_om_mat(filename):
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