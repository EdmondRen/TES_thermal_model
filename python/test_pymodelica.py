"""Regression tests for Python Modelica analysis helpers."""

import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import numpy as np

import pymodelica


class LinearCollectionEfficiencyTest(unittest.TestCase):
    """Test collection efficiency from precomputed linear responses."""

    @staticmethod
    def make_model(include_parasitic=True):
        """Create the minimal TESModel state required by the helper.

        Args:
            include_parasitic: Whether to include a series-resistance result.

        Returns:
            A partially initialized TESModel suitable for helper tests.
        """
        model = pymodelica.TESModel.__new__(pymodelica.TESModel)
        model.nparams = 3
        model.index_cload_v = 0
        model.index_tes_i = 1
        model.simulation_results = {
            "c1.v": np.array([2.0]),
            "c1.i": np.array([3.0]),
            "L.L": np.array([0.5]),
        }
        if include_parasitic:
            model.simulation_results["Rp.R"] = np.array([0.25])
        return model

    def test_integrates_precomputed_response_with_circuit_drops(self):
        """Include resistive and inductive drops in the TES voltage."""
        model = self.make_model()
        time = np.array([0.0, 1.0, 2.0])
        response = np.array(
            [
                [0.0, 0.0, 0.0],
                [-2.0, -1.0, 4.0],
                [-4.0, -2.0, 1.0],
            ]
        )

        result = model.get_linear_phonon_energy_collection_efficiency(
            time=time,
            impulse_response=response,
            deposited_energy=20.0,
        )

        integrated_current = -2.0
        integrated_load_voltage = -4.0
        integrated_tes_voltage = (
            integrated_load_voltage
            - 0.25 * integrated_current
            - 0.5 * (response[-1, 1] - response[0, 1])
        )
        expected_joule_energy = (
            2.0 * integrated_current + 3.0 * integrated_tes_voltage
        )
        self.assertAlmostEqual(result["joule_energy"], expected_joule_energy)
        self.assertAlmostEqual(result["collected_energy"], -expected_joule_energy)
        self.assertAlmostEqual(result["efficiency"], -expected_joule_energy / 20.0)
        self.assertEqual(result["integration_time"], 2.0)

    def test_missing_parasitic_resistance_defaults_to_zero(self):
        """Support older circuit models that do not contain Rp."""
        model = self.make_model(include_parasitic=False)
        time = np.array([0.0, 1.0])
        response = np.array([[0.0, 0.0, 0.0], [-2.0, -1.0, 0.0]])

        result = model.get_linear_phonon_energy_collection_efficiency(
            time,
            response,
            deposited_energy=10.0,
        )

        self.assertAlmostEqual(result["joule_energy"], -2.5)

    def test_rejects_invalid_response_inputs(self):
        """Reject malformed time grids, response arrays, and energies."""
        model = self.make_model()
        valid_response = np.zeros((2, 3))

        with self.assertRaisesRegex(ValueError, "strictly increasing"):
            model.get_linear_phonon_energy_collection_efficiency(
                [0.0, 0.0], valid_response, 1.0
            )
        with self.assertRaisesRegex(ValueError, "must have shape"):
            model.get_linear_phonon_energy_collection_efficiency(
                [0.0, 1.0], np.zeros((2, 2)), 1.0
            )
        with self.assertRaisesRegex(ValueError, "finite"):
            invalid_response = valid_response.copy()
            invalid_response[0, 0] = np.nan
            model.get_linear_phonon_energy_collection_efficiency(
                [0.0, 1.0], invalid_response, 1.0
            )
        with self.assertRaisesRegex(ValueError, "positive"):
            model.get_linear_phonon_energy_collection_efficiency(
                [0.0, 1.0], valid_response, 0.0
            )


class NonlinearEnergyTemplateTest(unittest.TestCase):
    """Test nonlinear current-pulse energy templates."""

    def test_normalizes_fft_and_keeps_final_duplicate_sample(self):
        """Deduplicate event samples before computing the normalized FFT."""
        model = pymodelica.TESModel.__new__(pymodelica.TESModel)
        time = np.array([0.0, 1.0, 1.0, 2.0, 3.0])
        current = np.array([5.0, 99.0, 6.0, 5.0, 5.0])

        frequencies, template = model.get_nonlinear_energy_template(
            time,
            deposited_energy=2.0,
            current=current,
            baseline_samples=1,
        )

        expected_delta_current = np.array([0.0, 1.0, 0.0, 0.0])
        expected_template = np.fft.rfft(expected_delta_current) / 2.0
        np.testing.assert_allclose(
            frequencies,
            np.fft.rfftfreq(len(expected_delta_current), 1.0),
        )
        np.testing.assert_allclose(template, expected_template)

    def test_accepts_result_dictionary_and_explicit_baseline(self):
        """Read the selected current result and honor an explicit baseline."""
        model = pymodelica.TESModel.__new__(pymodelica.TESModel)
        result = {"tes.i": np.array([3.0, 2.0, 3.0])}

        _, template = model.get_nonlinear_energy_template(
            [0.0, 0.5, 1.0],
            deposited_energy=0.5,
            simulation_result=result,
            current_key="tes.i",
            baseline_current=3.0,
        )

        expected = 0.5 * np.fft.rfft([0.0, -1.0, 0.0]) / 0.5
        np.testing.assert_allclose(template, expected)

    def test_rejects_invalid_template_inputs(self):
        """Reject conflicting, malformed, or physically invalid inputs."""
        model = pymodelica.TESModel.__new__(pymodelica.TESModel)
        valid_time = [0.0, 1.0]
        valid_current = [0.0, 0.0]

        with self.assertRaisesRegex(ValueError, "not both"):
            model.get_nonlinear_energy_template(
                valid_time,
                1.0,
                simulation_result={"c1.i": valid_current},
                current=valid_current,
            )
        with self.assertRaisesRegex(ValueError, "nondecreasing"):
            model.get_nonlinear_energy_template(
                [1.0, 0.0], 1.0, current=valid_current
            )
        with self.assertRaisesRegex(ValueError, "equal lengths"):
            model.get_nonlinear_energy_template(
                valid_time, 1.0, current=[0.0]
            )
        with self.assertRaisesRegex(ValueError, "positive"):
            model.get_nonlinear_energy_template(
                valid_time, 0.0, current=valid_current
            )
        with self.assertRaisesRegex(ValueError, "baseline_samples"):
            model.get_nonlinear_energy_template(
                valid_time, 1.0, current=valid_current, baseline_samples=3
            )


class ModelRunnerTest(unittest.TestCase):
    """Test isolated runner behavior used by MCMC."""

    def test_mcmc_requests_an_isolated_quiet_run(self):
        """Keep MCMC evaluations out of the shared build directory."""
        fit = pymodelica.TESMCMCFit(
            model_exe="model_exe",
            build_dir="build",
            full_model_file="model.mo",
            base_override_file="params.txt",
        )
        expected = {"run_dir": Path("temporary_run")}

        with mock.patch.object(
            pymodelica,
            "run_model",
            return_value=expected,
        ) as run_model_mock:
            result = fit.run_model({"TES_alpha": 40.0})

        self.assertEqual(result, expected)
        kwargs = run_model_mock.call_args.kwargs
        self.assertTrue(kwargs["copy_exe"])
        self.assertFalse(kwargs["verbose"])

    def test_runner_places_linear_model_and_separates_fine_arguments(self):
        """Build valid OpenModelica arguments inside a temporary run."""
        with tempfile.TemporaryDirectory() as temporary_directory:
            build_dir = Path(temporary_directory)
            model_name = "toy_exe"
            for filename in (
                model_name,
                f"{model_name}_init.xml",
                f"{model_name}_info.json",
                f"{model_name}_JacA.bin",
            ):
                (build_dir / filename).write_text("test", encoding="utf-8")
            override_file = build_dir / "params.txt"
            override_file.write_text("Edep=20\n", encoding="utf-8")

            def fake_subprocess_run(args, cwd, **kwargs):
                """Create the file emitted by an OpenModelica linearization."""
                del kwargs
                if any(argument.startswith("-l=") for argument in args):
                    (Path(cwd) / "linearized_model.py").write_text(
                        "def linearized_model():\n    return None\n",
                        encoding="utf-8",
                    )
                return subprocess.CompletedProcess(args, 0, "", "")

            with mock.patch.object(
                pymodelica.subprocess,
                "run",
                side_effect=fake_subprocess_run,
            ) as subprocess_mock:
                result = pymodelica.run_model(
                    model_exe=model_name,
                    build_dir=build_dir,
                    copy_exe=True,
                    override_file=override_file,
                    params={"Edep": 20.0},
                    equilibrium_time=1.0,
                    fine_stop_time=0.1,
                    fine_step_size=1e-6,
                    tolerance=1e-8,
                    linearized_model_file="toy_linearized.py",
                    keep_runs=True,
                    verbose=False,
                )

            self.assertNotEqual(Path(result["run_dir"]), build_dir)
            self.assertTrue(Path(result["linearized_model"]).exists())
            coarse_args = subprocess_mock.call_args_list[0].args[0]
            fine_args = subprocess_mock.call_args_list[1].args[0]
            self.assertIn("-maxStepSize=3e-06", fine_args)
            self.assertIn("-tolerance=1e-08", fine_args)
            self.assertFalse(
                any("maxStepSize" in argument and "tolerance" in argument for argument in fine_args)
            )
            coarse_override_name = next(
                argument.split("=", 1)[1]
                for argument in coarse_args
                if argument.startswith("-overrideFile=")
            )
            coarse_override = Path(result["run_dir"]) / coarse_override_name
            self.assertIn("Edep=20", coarse_override.read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
