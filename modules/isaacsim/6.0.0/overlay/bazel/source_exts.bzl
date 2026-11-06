"""The Isaac Sim extensions that can be built from source.

GENERATED from the Isaac Sim source tree by //bazel:gen_source_exts.py; see
//bazel/README.md.

Extensions with C++ are excluded; extensions with .ogn nodes are included, with
the information needed to generate their databases. Excluded, with reasons:
  * extensions with .ogn nodes whose premake does not declare where the
    generated code belongs
  * extensions with C++/CUDA sources -- need a native build against the carb
    SDK and USD headers
  * extensions that put `pip_prebundle` on sys.path and whose wheels are not on
    PyPI -- the ones that are get their prebundle built here
  * extensions declaring a Python module absent from the source tree -- a
    generator (usdGenSchema, pybind) produces it at build time
"""

# extension name -> {"dir": subdirectory of source/, "mapping": premake's
# source-path -> destination-directory rules, both relative to the extension,
# "ogn": where its generated OmniGraph code goes, if it has .ogn nodes,
# "pip_prebundle": the vendored-wheel bundle it needs, if any,
# "payloads": packman package -> where its payload goes inside the extension}
ISAACSIM_SOURCE_EXTS = {
    "isaacsim.app.about": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.app.setup": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
            "layouts": "layouts",
        },
    },
    "isaacsim.asset.exporter.urdf": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.asset.exporter.urdf.ui": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python": "isaacsim/asset/exporter/urdf/ui",
        },
    },
    "isaacsim.asset.gen.conveyor.ui": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.asset.gen.omap.ui": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.asset.importer.heightmap": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.asset.importer.mjcf": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "icons": "icons",
            "python/*.py": "isaacsim/asset/importer/mjcf",
            "python/impl": "isaacsim/asset/importer/mjcf/impl",
            "python/tests": "isaacsim/asset/importer/mjcf/tests",
        },
    },
    "isaacsim.asset.importer.mjcf.ui": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "icons": "icons",
            "python/*.py": "isaacsim/asset/importer/mjcf/ui",
            "python/impl": "isaacsim/asset/importer/mjcf/ui/impl",
            "python/tests": "isaacsim/asset/importer/mjcf/ui/tests",
        },
    },
    "isaacsim.asset.importer.urdf": {
        "dir": "extensions",
        "mapping": {
            "$root/_build/target-deps/isaac_urdf_usd_prebundle": "pip_prebundle",
            "data": "data",
            "docs": "docs",
            "icons": "icons",
            "python/*.py": "isaacsim/asset/importer/urdf",
            "python/impl": "isaacsim/asset/importer/urdf/impl",
            "python/tests": "isaacsim/asset/importer/urdf/tests",
        },
        "pip_prebundle": "isaac_urdf_usd_prebundle",
    },
    "isaacsim.asset.importer.urdf.ui": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "icons": "icons",
            "python/*.py": "isaacsim/asset/importer/urdf/ui",
            "python/impl": "isaacsim/asset/importer/urdf/ui/impl",
            "python/tests": "isaacsim/asset/importer/urdf/ui/tests",
        },
    },
    "isaacsim.asset.importer.utils": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/*.py": "isaacsim/asset/importer/utils",
            "python/impl": "isaacsim/asset/importer/utils/impl",
            "python/tests": "isaacsim/asset/importer/utils/tests",
        },
    },
    "isaacsim.asset.transformer": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.asset.transformer.rules": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.asset.transformer.ui": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "icons": "icons",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.asset.validation": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.benchmark.services": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.code_editor.jupyter": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.code_editor.python_server": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.code_editor.vscode": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.core.deprecation_manager": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.core.experimental.actuators": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/__init__.py": "isaacsim/core/experimental/actuators",
            "python/impl": "isaacsim/core/experimental/actuators/impl",
            "python/nodes": "isaacsim/core/experimental/actuators/nodes",
            "python/tests": "isaacsim/core/experimental/actuators/tests",
        },
        "ogn": {
            "module": "isaacsim/core/experimental/actuators",
            "node_dirs": ["python/nodes"],
            "src_dirs": ["python/nodes"],
        },
    },
    "isaacsim.core.experimental.materials": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/*.py": "isaacsim/core/experimental/materials",
            "python/impl": "isaacsim/core/experimental/materials/impl",
            "python/tests": "isaacsim/core/experimental/materials/tests",
        },
    },
    "isaacsim.core.experimental.objects": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/*.py": "isaacsim/core/experimental/objects",
            "python/impl": "isaacsim/core/experimental/objects/impl",
            "python/tests": "isaacsim/core/experimental/objects/tests",
        },
    },
    "isaacsim.core.experimental.utils": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/*.py": "isaacsim/core/experimental/utils",
            "python/impl": "isaacsim/core/experimental/utils/impl",
            "python/mock/*.py": "isaacsim/core/experimental/utils",
            "python/tests": "isaacsim/core/experimental/utils/tests",
        },
    },
    "isaacsim.core.prims": {
        "dir": "deprecated",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/*.py": "isaacsim/core/prims",
            "python/impl": "isaacsim/core/prims/impl",
            "python/tests": "isaacsim/core/prims/tests",
        },
    },
    "isaacsim.core.rendering_manager": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/*.py": "isaacsim/core/rendering_manager",
            "python/impl": "isaacsim/core/rendering_manager/impl",
            "python/tests": "isaacsim/core/rendering_manager/tests",
        },
    },
    "isaacsim.core.throttling": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.core.version": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.cortex.behaviors": {
        "dir": "deprecated",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.cortex.examples": {
        "dir": "deprecated",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.cortex.framework": {
        "dir": "deprecated",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.examples.base": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.examples.browser": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.examples.extension": {
        "dir": "deprecated",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
            "template_source_files": "template_source_files",
        },
    },
    "isaacsim.examples.interactive": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.examples.ui": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.gui.components": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.gui.content_browser": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "icons": "icons",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.gui.menu": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.gui.property": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.gui.sensors.icon": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "icons": "icons",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.hsb.bridge": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/__init__.py": "isaacsim/hsb/bridge",
            "python/extension.py": "isaacsim/hsb/bridge",
        },
    },
    "isaacsim.physics.newton": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/__init__.py": "isaacsim/physics/newton/__init__.py",
            "python/impl": "isaacsim/physics/newton/impl",
            "python/impl/tensors": "isaacsim/physics/newton/tensors",
            "python/tests": "isaacsim/physics/newton/tests",
        },
    },
    "isaacsim.physics.newton.ui": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.pip.newton": {
        "dir": "extensions",
        "mapping": {
            "$root/_build/target-deps/isaac_newton_prebundle": "pip_prebundle",
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
        "pip_prebundle": "isaac_newton_prebundle",
    },
    "isaacsim.replicator.behavior": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.replicator.behavior.ui": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.replicator.domain_randomization": {
        "dir": "deprecated",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/__init__.py": "isaacsim/replicator/domain_randomization",
            "python/impl": "isaacsim/replicator/domain_randomization/impl",
            "python/scripts": "isaacsim/replicator/domain_randomization/scripts",
            "python/tests": "isaacsim/replicator/domain_randomization/tests",
        },
    },
    "isaacsim.replicator.episode_recorder.ui": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.replicator.examples": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/__init__.py": "isaacsim/replicator/examples",
            "python/impl": "isaacsim/replicator/examples/impl",
            "python/tests": "isaacsim/replicator/examples/tests",
        },
        "ogn": {
            "module": "isaacsim/replicator/examples",
            "node_dirs": ["python/nodes"],
            "src_dirs": ["python/nodes"],
        },
    },
    "isaacsim.replicator.experimental.domain_randomization": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/__init__.py": "isaacsim/replicator/experimental/domain_randomization",
            "python/impl": "isaacsim/replicator/experimental/domain_randomization/impl",
            "python/scripts": "isaacsim/replicator/experimental/domain_randomization/scripts",
            "python/tests": "isaacsim/replicator/experimental/domain_randomization/tests",
        },
        "ogn": {
            "module": "isaacsim/replicator/experimental/domain_randomization",
            "node_dirs": ["python/nodes"],
            "src_dirs": ["python/nodes"],
        },
    },
    "isaacsim.replicator.grasping": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.replicator.grasping.ui": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.replicator.mobility_gen.examples": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.replicator.mobility_gen.ui": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.replicator.synthetic_recorder": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.replicator.teleop.ui": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.replicator.writers": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/__init__.py": "isaacsim/replicator/writers",
            "python/impl": "isaacsim/replicator/writers/impl",
            "python/scripts": "isaacsim/replicator/writers/scripts",
            "python/tests": "isaacsim/replicator/writers/tests",
        },
        "ogn": {
            "module": "isaacsim/replicator/writers",
            "node_dirs": ["python/nodes"],
            "src_dirs": ["python/nodes"],
        },
    },
    "isaacsim.robot.experimental.manipulators.examples": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.robot.experimental.wheeled_robots": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.robot.manipulators": {
        "dir": "deprecated",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/__init__.py": "isaacsim/robot/manipulators",
            "python/controllers": "isaacsim/robot/manipulators/controllers",
            "python/grippers": "isaacsim/robot/manipulators/grippers",
            "python/impl": "isaacsim/robot/manipulators/impl",
            "python/manipulators": "isaacsim/robot/manipulators/manipulators",
            "python/nodes": "isaacsim/robot/manipulators/nodes",
            "python/tests": "isaacsim/robot/manipulators/tests",
        },
        "ogn": {
            "module": "isaacsim/robot/manipulators",
            "node_dirs": ["python/nodes"],
            "src_dirs": ["python/nodes"],
        },
    },
    "isaacsim.robot.manipulators.examples": {
        "dir": "deprecated",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.robot.manipulators.ui": {
        "dir": "deprecated",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.robot.policy.examples": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.robot.poser": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.robot.poser.ui": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "icons": "icons",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.robot.schema": {
        "dir": "extensions",
        "mapping": {
            "config": "config",
            "data": "data",
            "docs": "docs",
            "include": "include",
            "python/__init__.py": "usd/schema/isaac",
            "python/compat": "compat",
            "python/tests": "isaacsim/robot/schema/tests",
            "range_sensor_schema": "usd/schema/isaac/range_sensor_schema",
            "robot_schema": "usd/schema/isaac/robot_schema",
            "sensor_schema": "usd/schema/isaac/sensor_schema",
        },
    },
    "isaacsim.robot.schema.ui": {
        "dir": "extensions",
        "mapping": {
            "config": "config",
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.robot.surface_gripper.ui": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.robot.wheeled_robots.ui": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.robot_motion.cumotion.examples": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.robot_motion.experimental.motion_generation": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python": "isaacsim/robot_motion/experimental/motion_generation",
        },
    },
    "isaacsim.robot_motion.lula_test_widget": {
        "dir": "deprecated",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.robot_motion.motion_generation": {
        "dir": "deprecated",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
            "motion_policy_configs": "motion_policy_configs",
            "path_planner_configs": "path_planner_configs",
        },
    },
    "isaacsim.robot_motion.motion_generation.examples": {
        "dir": "deprecated",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.robot_motion.pink.examples": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.robot_motion.schema": {
        "dir": "extensions",
        "mapping": {
            "config": "config",
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
            "robot_motion_schema": "usd/schema/isaac/robot_motion_schema",
        },
    },
    "isaacsim.robot_setup.assembler": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "icons": "icons",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.robot_setup.collision_detector": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "icons": "icons",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.robot_setup.gain_tuner": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "icons": "icons",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.robot_setup.grasp_editor": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.robot_setup.wizard": {
        "dir": "deprecated",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "icons": "icons",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.robot_setup.xrdf_editor": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.ros2.bridge": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/*.py": "isaacsim/ros2/bridge",
            "python/impl": "isaacsim/ros2/bridge/impl",
        },
    },
    "isaacsim.ros2.sim_control": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/*.py": "isaacsim/ros2/sim_control",
            "python/impl": "isaacsim/ros2/sim_control/impl",
            "python/tests": "isaacsim/ros2/sim_control/tests",
        },
    },
    "isaacsim.ros2.ui": {
        "dir": "extensions",
        "mapping": {
            "config": "config",
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.ros2.urdf": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.sensors.camera": {
        "dir": "deprecated",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.sensors.camera.ui": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.sensors.experimental.rtx": {
        "dir": "extensions",
        "mapping": {
            "%{root}/_build/target-deps/generic_model_output/%{platform}/%{config}/omni/sensors": "isaacsim/sensors/experimental/rtx",
            "%{root}/_build/target-deps/sensor-checker/%{platform}/%{config}/omni/sensors": "isaacsim/sensors/experimental/rtx",
            "data": "data",
            "docs": "docs",
            "python/*.py": "isaacsim/sensors/experimental/rtx",
            "python/impl": "isaacsim/sensors/experimental/rtx/impl",
            "python/tests": "isaacsim/sensors/experimental/rtx/tests",
        },
        "payloads": {
            "generic_model_output": "isaacsim/sensors/experimental/rtx",
            "sensor-checker": "isaacsim/sensors/experimental/rtx",
        },
    },
    "isaacsim.sensors.physics.ui": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.sensors.physx.ui": {
        "dir": "deprecated",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.sensors.rtx.ui": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.simulation_app": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.storage.native": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.streaming.rtsp": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/__init__.py": "isaacsim/streaming/rtsp",
            "python/impl": "isaacsim/streaming/rtsp/impl",
            "python/nodes": "isaacsim/streaming/rtsp/nodes",
            "python/tests": "isaacsim/streaming/rtsp/tests",
        },
        "ogn": {
            "module": "isaacsim/streaming/rtsp",
            "node_dirs": ["python/nodes"],
            "src_dirs": ["python/nodes"],
        },
    },
    "isaacsim.test.collection": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.test.docstring": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.test.utils": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.ucx.bridge": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/*.py": "isaacsim/ucx/bridge",
            "python/impl": "isaacsim/ucx/bridge/impl",
        },
    },
    "isaacsim.util.camera_inspector": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.util.merge_mesh": {
        "dir": "deprecated",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
    "isaacsim.util.physics": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "isaacsim": "isaacsim",
        },
    },
}

ISAACSIM_NATIVE_EXTS = {
    "isaacsim.asset.gen.conveyor": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/__init__.py": "isaacsim/asset/gen/conveyor",
            "python/commands": "isaacsim/asset/gen/conveyor/commands",
            "python/impl": "isaacsim/asset/gen/conveyor/impl",
            "python/tests": "isaacsim/asset/gen/conveyor/tests",
        },
        "ogn": {
            "module": "isaacsim/asset/gen/conveyor",
            "node_dirs": [],
            "src_dirs": ["nodes"],
        },
    },
    "isaacsim.core.api": {
        "dir": "deprecated",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/impl/*.py": "isaacsim/core/api",
            "python/impl/articulations": "isaacsim/core/api/articulations",
            "python/impl/controllers": "isaacsim/core/api/controllers",
            "python/impl/loggers": "isaacsim/core/api/loggers",
            "python/impl/materials": "isaacsim/core/api/materials",
            "python/impl/objects": "isaacsim/core/api/objects",
            "python/impl/physics_context": "isaacsim/core/api/physics_context",
            "python/impl/robots": "isaacsim/core/api/robots",
            "python/impl/scenes": "isaacsim/core/api/scenes",
            "python/impl/sensors": "isaacsim/core/api/sensors",
            "python/impl/simulation_context": "isaacsim/core/api/simulation_context",
            "python/impl/tasks": "isaacsim/core/api/tasks",
            "python/impl/world": "isaacsim/core/api/world",
            "python/tests": "isaacsim/core/api/tests",
        },
    },
    "isaacsim.core.cloner": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/*.py": "isaacsim/core/cloner",
            "python/impl": "isaacsim/core/cloner/impl",
            "python/tests": "isaacsim/core/cloner/tests",
        },
    },
    "isaacsim.core.experimental.primdata": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
        },
    },
    "isaacsim.core.experimental.prims": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "include": "include",
            "python/*.py": "isaacsim/core/experimental/prims",
            "python/impl": "isaacsim/core/experimental/prims/impl",
            "python/tests": "isaacsim/core/experimental/prims/tests",
        },
    },
    "isaacsim.core.includes": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "include": "include",
        },
    },
    "isaacsim.core.nodes": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "include": "include",
            "python/__init__.py": "isaacsim/core/nodes",
            "python/impl": "isaacsim/core/nodes/impl",
            "python/scripts": "isaacsim/core/nodes/scripts",
            "python/tests": "isaacsim/core/nodes/tests",
        },
        "ogn": {
            "module": "isaacsim/core/nodes",
            "node_dirs": ["python/nodes"],
            "src_dirs": ["nodes", "python/nodes"],
        },
    },
    "isaacsim.core.simulation_manager": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "include": "include",
            "python/*.py": "isaacsim/core/simulation_manager",
            "python/impl": "isaacsim/core/simulation_manager/impl",
            "python/tests": "isaacsim/core/simulation_manager/tests",
        },
    },
    "isaacsim.core.utils": {
        "dir": "deprecated",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/impl/*.py": "isaacsim/core/utils",
            "python/impl/numpy": "isaacsim/core/utils/numpy",
            "python/impl/torch": "isaacsim/core/utils/torch",
            "python/impl/warp": "isaacsim/core/utils/warp",
            "python/tests": "isaacsim/core/utils/tests",
        },
    },
    "isaacsim.examples.ipc": {
        "dir": "extensions",
        "mapping": {
            "bindings/__init__.py": "isaacsim/examples/ipc/bindings",
            "data": "data",
            "docs": "docs",
            "nodes": "nodes",
            "python/__init__.py": "isaacsim/examples/ipc",
            "python/extension.py": "isaacsim/examples/ipc",
            "python/nodes": "isaacsim/examples/ipc/nodes",
            "python/scripts": "isaacsim/examples/ipc/scripts",
            "python/tests": "isaacsim/examples/ipc/tests",
        },
        "ogn": {
            "module": "isaacsim/examples/ipc",
            "node_dirs": ["python/nodes", "nodes"],
            "src_dirs": ["nodes", "python/nodes"],
        },
    },
    "isaacsim.hsb.core": {
        "dir": "extensions",
        "mapping": {
            "bindings/__init__.py": "isaacsim/hsb/core/bindings",
            "data": "data",
            "docs": "docs",
            "include": "include",
            "python/__init__.py": "isaacsim/hsb/core",
            "python/extension.py": "isaacsim/hsb/core",
        },
    },
    "isaacsim.hsb.nodes": {
        "dir": "extensions",
        "mapping": {
            "bindings/__init__.py": "isaacsim/hsb/nodes/bindings",
            "data": "data",
            "docs": "docs",
            "include": "include",
            "nodes": "nodes",
            "python/__init__.py": "isaacsim/hsb/nodes",
            "python/extension.py": "isaacsim/hsb/nodes",
            "python/nodes": "isaacsim/hsb/nodes/nodes",
            "python/tests/*.py": "isaacsim/hsb/nodes/tests",
            "python/tests/__init__.py": "isaacsim/hsb/nodes/tests",
        },
        "ogn": {
            "module": "isaacsim/hsb/nodes",
            "node_dirs": ["python/nodes", "nodes"],
            "src_dirs": ["nodes", "python/nodes"],
        },
    },
    "isaacsim.physics.newton.tensors": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/__init__.py": "isaacsim/physics/newton/tensors/__init__.py",
            "python/impl": "isaacsim/physics/newton/tensors/impl",
            "python/tests": "isaacsim/physics/newton/tensors/tests",
        },
    },
    "isaacsim.replicator.experimental.mobility_gen": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/*.py": "isaacsim/replicator/experimental/mobility_gen",
            "python/impl": "isaacsim/replicator/experimental/mobility_gen/impl",
            "python/tests": "isaacsim/replicator/experimental/mobility_gen/tests",
        },
    },
    "isaacsim.replicator.mobility_gen": {
        "dir": "deprecated",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/*.py": "isaacsim/replicator/mobility_gen",
            "python/impl": "isaacsim/replicator/mobility_gen/impl",
            "python/tests": "isaacsim/replicator/mobility_gen/tests",
        },
    },
    "isaacsim.robot.surface_gripper": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "include": "include",
            "python/*.py": "isaacsim/robot/surface_gripper",
            "python/impl": "isaacsim/robot/surface_gripper/impl",
            "python/tests": "isaacsim/robot/surface_gripper/tests",
        },
        "ogn": {
            "module": "isaacsim/robot/surface_gripper",
            "node_dirs": ["python/nodes"],
            "src_dirs": ["python/nodes"],
        },
    },
    "isaacsim.robot.wheeled_robots": {
        "dir": "deprecated",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/__init__.py": "isaacsim/robot/wheeled_robots",
            "python/controllers": "isaacsim/robot/wheeled_robots/controllers",
            "python/impl": "isaacsim/robot/wheeled_robots/impl",
            "python/robots": "isaacsim/robot/wheeled_robots/robots",
            "python/tests": "isaacsim/robot/wheeled_robots/tests",
        },
    },
    "isaacsim.robot.wheeled_robots.nodes": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/__init__.py": "isaacsim/robot/wheeled_robots/nodes",
            "python/impl": "isaacsim/robot/wheeled_robots/nodes/impl",
            "python/nodes": "isaacsim/robot/wheeled_robots/nodes/nodes",
            "python/tests": "isaacsim/robot/wheeled_robots/nodes/tests",
        },
        "ogn": {
            "module": "isaacsim/robot/wheeled_robots/nodes",
            "node_dirs": ["python/nodes", "nodes"],
            "src_dirs": ["nodes", "python/nodes"],
        },
    },
    "isaacsim.ros2.nodes": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/__init__.py": "isaacsim/ros2/nodes",
            "python/impl": "isaacsim/ros2/nodes/impl",
            "python/nodes": "isaacsim/ros2/nodes/nodes",
            "python/tests": "isaacsim/ros2/nodes/tests",
        },
        "ogn": {
            "module": "isaacsim/ros2/nodes",
            "node_dirs": ["python/nodes", "nodes"],
            "src_dirs": ["nodes", "python/nodes"],
        },
    },
    "isaacsim.ros2.tf_viewer": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/*.py": "isaacsim/ros2/tf_viewer",
            "python/impl": "isaacsim/ros2/tf_viewer/impl",
            "python/tests": "isaacsim/ros2/tf_viewer/tests",
        },
    },
    "isaacsim.sensors.experimental.physics": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "include": "include",
            "python/*.py": "isaacsim/sensors/experimental/physics",
            "python/impl": "isaacsim/sensors/experimental/physics/impl",
            "python/tests": "isaacsim/sensors/experimental/physics/tests",
        },
    },
    "isaacsim.sensors.physics": {
        "dir": "deprecated",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "include": "include",
            "python/*.py": "isaacsim/sensors/physics",
            "python/impl": "isaacsim/sensors/physics/impl",
            "python/tests": "isaacsim/sensors/physics/tests",
        },
    },
    "isaacsim.sensors.physics.nodes": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/*.py": "isaacsim/sensors/physics/nodes",
            "python/impl": "isaacsim/sensors/physics/nodes/impl",
            "python/nodes": "isaacsim/sensors/physics/nodes/nodes",
            "python/tests": "isaacsim/sensors/physics/nodes/tests",
        },
        "ogn": {
            "module": "isaacsim/sensors/physics/nodes",
            "node_dirs": ["python/nodes"],
            "src_dirs": ["nodes"],
        },
    },
    "isaacsim.sensors.physx": {
        "dir": "deprecated",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "include": "include",
            "python/*.py": "isaacsim/sensors/physx",
            "python/impl": "isaacsim/sensors/physx/impl",
            "python/tests": "isaacsim/sensors/physx/tests",
        },
        "ogn": {
            "module": "isaacsim/sensors/physx",
            "node_dirs": [],
            "src_dirs": ["nodes"],
        },
    },
    "isaacsim.sensors.rtx": {
        "dir": "deprecated",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/__init__.py": "isaacsim/sensors/rtx",
            "python/generic_model_output": "isaacsim/sensors/rtx/generic_model_output",
            "python/impl": "isaacsim/sensors/rtx/impl",
            "python/sensor_checker": "isaacsim/sensors/rtx/sensor_checker",
            "python/tests": "isaacsim/sensors/rtx/tests",
        },
        "ogn": {
            "module": "isaacsim/sensors/rtx",
            "node_dirs": [],
            "src_dirs": ["nodes"],
        },
    },
    "isaacsim.sensors.rtx.nodes": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "python/__init__.py": "isaacsim/sensors/rtx/nodes",
            "python/impl": "isaacsim/sensors/rtx/nodes/impl",
            "python/tests": "isaacsim/sensors/rtx/nodes/tests",
        },
        "ogn": {
            "module": "isaacsim/sensors/rtx/nodes",
            "node_dirs": [],
            "src_dirs": ["nodes"],
        },
    },
    "isaacsim.ucx.nodes": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "include": "include",
            "python/__init__.py": "isaacsim/ucx/nodes",
            "python/extension.py": "isaacsim/ucx/nodes",
            "python/nodes": "isaacsim/ucx/nodes/nodes",
            "python/tests": "isaacsim/ucx/nodes/tests",
        },
        "ogn": {
            "module": "isaacsim/ucx/nodes",
            "node_dirs": ["python/nodes", "nodes"],
            "src_dirs": ["nodes", "python/nodes"],
        },
    },
    "omni.kit.loop-isaac": {
        "dir": "extensions",
        "mapping": {
            "data": "data",
            "docs": "docs",
            "include": "include",
            "python/*.py": "omni/kit/loop",
            "python/tests": "omni/kit/loop/tests",
        },
    },
}
