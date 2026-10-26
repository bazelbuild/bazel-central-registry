/**
 * Comprehensive test suite for yosys binary functionality
 */

#include <gtest/gtest.h>

#include <cassert>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <functional>
#include <iostream>
#include <memory>
#include <sstream>
#include <stdexcept>
#include <string>
#include <vector>

#include "rules_cc/cc/runfiles/runfiles.h"

/** Helper function to execute a command and capture output */
std::string exec(const std::string& cmd) {
    char buffer[128];
    std::string result = "";
    std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd.c_str(), "r"),
                                                  pclose);
    if (!pipe) {
        throw std::runtime_error("popen() failed!");
    }
    while (fgets(buffer, sizeof buffer, pipe.get()) != nullptr) {
        result += buffer;
    }
    return result;
}

/** Helper function to create a temporary file with content */
void create_temp_file(const std::string& filename, const std::string& content) {
    std::ofstream file(filename);
    if (!file.is_open()) {
        throw std::runtime_error("Could not create temporary file: " +
                                 filename);
    }
    file << content;
    file.close();
}

/** Helper function to check if a file exists */
bool file_exists(const std::string& filename) {
    std::ifstream file(filename);
    return file.good();
}

class YosysTest : public ::testing::Test {
   protected:
    void SetUp() override {
        // Use runfiles to locate the yosys binary
        std::string error;
        std::unique_ptr<rules_cc::cc::runfiles::Runfiles> runfiles(
            rules_cc::cc::runfiles::Runfiles::CreateForTest(
                BAZEL_CURRENT_REPOSITORY, &error));

        if (runfiles == nullptr) {
            FAIL() << "Failed to create runfiles: " << error;
        }

        const char* yosys_env = std::getenv("YOSYS");
        if (!yosys_env) {
            FAIL() << "Could not locate yosys binary using runfiles, "
                      "environment variable, or command line argument";
        }

        yosys_path = runfiles->Rlocation(yosys_env);
        if (yosys_path.empty()) {
            FAIL() << "Failed to locate yosys binary in runfiles.";
        }

        const char* tmpdir = std::getenv("TEST_TMPDIR");
        if (!tmpdir) {
            FAIL() << "TEST_TMPDIR environment variable is not set";
        }
        test_tmpdir = tmpdir;
    }

    /** Helper: prepend TEST_TMPDIR to filenames */
    std::string temp_path(const std::string& filename) const {
        return test_tmpdir + "/" + filename;
    }

    std::string yosys_path;
    std::string test_tmpdir;

   public:
    static int argc;
    static char** argv;
};

/** Static members for command line arguments */
int YosysTest::argc = 0;
char** YosysTest::argv = nullptr;

/** Test that yosys binary can be executed and shows version */
TEST_F(YosysTest, VersionCommand) {
    std::string cmd = yosys_path + " -V";
    std::string output = exec(cmd);

    EXPECT_TRUE(output.find("Yosys") != std::string::npos)
        << "Version output doesn't contain 'Yosys': " << output;
}

/** Test that yosys binary can show help */
TEST_F(YosysTest, HelpCommand) {
    std::string cmd = yosys_path + " -h";
    std::string output = exec(cmd);

    EXPECT_TRUE(output.find("Usage:") != std::string::npos ||
                output.find("usage:") != std::string::npos)
        << "Help output doesn't contain usage information: " << output;
}

/**
 * Test basic command help functionality (equivalent to
 * yosys_basic_commands_test)
 */
TEST_F(YosysTest, BasicCommandsHelp) {
    // Test design command help
    std::string cmd = yosys_path + " -p 'help design' 2>&1";
    std::string output = exec(cmd);

    EXPECT_TRUE(output.find("design") != std::string::npos)
        << "Design command help not working: " << output;

    // Test hierarchy command help
    cmd = yosys_path + " -p 'help hierarchy' 2>&1";
    output = exec(cmd);

    EXPECT_TRUE(output.find("hierarchy") != std::string::npos)
        << "Hierarchy command help not working: " << output;

    // Test synth command help
    cmd = yosys_path + " -p 'help synth' 2>&1";
    output = exec(cmd);

    EXPECT_TRUE(output.find("synth") != std::string::npos)
        << "Synth command help not working: " << output;
}

/** Test basic synthesis flow */
TEST_F(YosysTest, BasicSynthesis) {
    // Create a simple Verilog file
    std::string verilog_content =
        "module simple(input a, b, output y); assign y = a & b; endmodule\n";
    std::string input_file = temp_path("test_simple.v");
    std::string output_file = temp_path("test_output.il");
    create_temp_file(input_file, verilog_content);

    // Run basic synthesis without techmap (which requires share/ directory
    // setup)

    std::string cmd =
        yosys_path + " -p 'read_verilog " + input_file +
        "; hierarchy; proc; opt; fsm; opt; memory; opt; write_rtlil " +
        output_file + "' 2>&1";
    std::string output = exec(cmd);

    // Check for successful completion (should not contain "ERROR")
    EXPECT_TRUE(output.find("ERROR") == std::string::npos)
        << "Synthesis failed with error: " << output;

    // Check that output file was created
    EXPECT_TRUE(file_exists(output_file))
        << "Synthesis did not create output file";
}

/** Test autoname functionality (equivalent to yosys_autoname_test) */
TEST_F(YosysTest, AutonameFunctionality) {
    // Create RTLIL test file
    std::string rtlil_content = R"(autoidx 2
module \top
  wire output 3 $y
  wire input 1 \a
  wire input 2 \b
  cell $and \b_$and_B
    parameter \A_SIGNED 0
    parameter \A_WIDTH 1
    parameter \B_SIGNED 0
    parameter \B_WIDTH 1
    parameter \Y_WIDTH 1
    connect \A \a
    connect \B \b
    connect \Y $y
  end
end
)";
    std::string input_file = temp_path("autoname_test.rtlil");
    std::string output_file = temp_path("autoname_output.il");
    create_temp_file(input_file, rtlil_content);

    // Run autoname command

    std::string cmd = yosys_path + " -p 'read_rtlil " + input_file +
                      "; autoname; write_rtlil " + output_file + "' 2>&1";
    std::string output = exec(cmd);

    // Check for successful completion
    EXPECT_TRUE(output.find("ERROR") == std::string::npos)
        << "Autoname failed with error: " << output;

    // Check that output file was created
    EXPECT_TRUE(file_exists(output_file))
        << "Autoname did not create output file";
}

/**
 * Test simple synthesis with synth command (equivalent to
 * yosys_simple_synthesis_test)
 */
TEST_F(YosysTest, SimpleSynthesisWithSynth) {
    // Create a simple Verilog file
    std::string verilog_content =
        "module simple(input a, b, output y); assign y = a & b; endmodule\n";
    std::string input_file = temp_path("simple.v");
    std::string output_file = temp_path("simple.il");
    create_temp_file(input_file, verilog_content);

    // Run synthesis using synth command but without techmap (which requires
    // share/ directory)
    std::string cmd =
        yosys_path + " -p 'read_verilog " + input_file +
        "; hierarchy; proc; opt; fsm; opt; memory; opt; write_rtlil " +
        output_file + "' 2>&1";
    std::string output = exec(cmd);

    // Check for successful completion
    EXPECT_TRUE(output.find("ERROR") == std::string::npos)
        << "Simple synthesis with synth command failed: " << output;

    // Check that output file was created
    EXPECT_TRUE(file_exists(output_file))
        << "Simple synthesis did not create output file";
}

/** Test that yosys can handle multiple commands in sequence */
TEST_F(YosysTest, MultipleCommandsSequence) {
    std::string cmd =
        yosys_path + " -p 'help design; help hierarchy; help synth' 2>&1";
    std::string output = exec(cmd);

    // Should contain help for all three commands
    EXPECT_TRUE(output.find("design") != std::string::npos)
        << "Multiple commands sequence failed - design help missing: "
        << output;
    EXPECT_TRUE(output.find("hierarchy") != std::string::npos)
        << "Multiple commands sequence failed - hierarchy help missing: "
        << output;
    EXPECT_TRUE(output.find("synth") != std::string::npos)
        << "Multiple commands sequence failed - synth help missing: " << output;
}

/** Test error handling for invalid commands */
TEST_F(YosysTest, ErrorHandling) {
    std::string cmd = yosys_path + " -p 'invalid_command' 2>&1";
    std::string output = exec(cmd);

    // Should contain error message
    EXPECT_TRUE(output.find("ERROR") != std::string::npos ||
                output.find("No such command") != std::string::npos)
        << "Error handling test failed - should show error for invalid "
           "command: "
        << output;
}

/** Test that yosys can read and write different file formats */
TEST_F(YosysTest, FileFormatSupport) {
    // Test RTLIL format with a valid simple module
    std::string rtlil_content = R"(module \test
  wire input 1 \a
  wire output 1 \y
  cell $not \not1
    parameter \A_SIGNED 0
    parameter \A_WIDTH 1
    parameter \Y_WIDTH 1
    connect \A \a
    connect \Y \y
  end
end
)";
    std::string input_file = temp_path("test.rtlil");
    std::string output_file = temp_path("test_out.rtlil");
    create_temp_file(input_file, rtlil_content);

    std::string cmd = yosys_path + " -p 'read_rtlil " + input_file +
                      "; write_rtlil " + output_file + "' 2>&1";
    std::string output = exec(cmd);

    EXPECT_TRUE(output.find("ERROR") == std::string::npos)
        << "RTLIL format support failed: " << output;

    EXPECT_TRUE(file_exists(output_file))
        << "RTLIL output file was not created";
}

int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);

    // Store command line arguments for use in tests
    YosysTest::argc = argc;
    YosysTest::argv = argv;

    return RUN_ALL_TESTS();
}
