package integrity_test

import (
	"flag"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"

	"github.com/bazelbuild/rules_go/go/runfiles"
)

var smoke = flag.String("smoke", "", "smoke test runfile")
var breakHash = flag.String("break-hash", "", "upstream hash corruption tool runfile")

func TestIntegrity(t *testing.T) {
	binary, err := runfiles.Rlocation(*smoke)
	if err != nil {
		t.Fatal(err)
	}
	breaker, err := runfiles.Rlocation(*breakHash)
	if err != nil {
		t.Fatal(err)
	}
	if output, err := exec.Command(binary).CombinedOutput(); err != nil {
		t.Fatalf("intact module failed: %v\n%s", err, output)
	}
	corrupted := filepath.Join(t.TempDir(), "corrupted")
	if output, err := exec.Command(breaker, binary, corrupted).CombinedOutput(); err != nil {
		t.Fatalf("could not corrupt module: %v\n%s", err, output)
	}
	output, err := exec.Command(corrupted).CombinedOutput()
	if err == nil {
		t.Fatal("corrupted module passed its integrity check")
	}
	if !strings.Contains(string(output), "FIPS integrity test") {
		t.Fatalf("corrupted module failed for an unexpected reason: %v\n%s", err, output)
	}
}
