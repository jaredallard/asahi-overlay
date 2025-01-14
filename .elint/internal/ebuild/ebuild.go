// Copyright (C) 2023 Jared Allard <jared@rgst.io>
// Copyright (C) 2023 Outreach <https://outreach.io>
//
// This program is free software: you can redistribute it and/or
// modify it under the terms of the GNU General Public License version
// 2 as published by the Free Software Foundation.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

// Package ebuild exposes functionality for parsing and working with
// Gentoo ebuilds[1].
//
// [1]: https://devmanual.gentoo.org/ebuild-writing/
package ebuild

import (
	"bytes"
	_ "embed"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/pkg/errors"
)

// ebuildStubs is a set of bash functions used for parsing ebuilds.
// Currently only contains stub functions to prevent errors when
// parsing.
//
//go:embed embed/ebuild-stubs.sh
var ebuildStubs string

// Ebuild is a Gentoo Ebuild.
type Ebuild struct {
	// EAPI is the EAPI[1] of the ebuild. Only 8 is currently supported.
	//
	// [1]: https://wiki.gentoo.org/wiki/EAPI
	EAPI int

	// Name is the name of the ebuild as derived from the filename.
	Name string

	// Version is the version of the ebuild as derived from the filename.
	Version string

	// License is the license of the ebuild.
	License string

	// Description is the description of the ebuild.
	Description string
}

// Parse parses an ebuild at the given path.
func Parse(path string) (*Ebuild, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, err
	}

	b, err := io.ReadAll(f)
	if err != nil {
		return nil, err
	}

	return parse(filepath.Base(path), b)
}

// parse parses the provided bytes as an ebuild.
func parse(fileName string, b []byte) (*Ebuild, error) {
	f, err := os.CreateTemp("", "linter-ebuild-*.ebuild")
	if err != nil {
		return nil, err
	}
	defer os.Remove(f.Name())

	if _, err := io.Copy(f, bytes.NewReader(b)); err != nil {
		return nil, err
	}

	// close the file to ensure that the file is flushed to disk.
	if err := f.Close(); err != nil {
		return nil, err
	}

	// Parse the ebuild via bash. We use -o pipefail and -e to ensure that
	// we accurately capture errors. We use "allexport" to automatically
	// export all env vars set by the ebuild. Then, we run 'env' to read
	// out the environment variables.
	cmd := exec.Command(
		"bash", "-o", "pipefail", "-o", "allexport", "-ec",
		ebuildStubs+"\n"+"source \"${0}\"; env", f.Name(),
	)
	cmd.Env = []string{} // don't want extra env vars messing with the output.
	out, err := cmd.Output()
	if err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			return nil, errors.Wrapf(err, "failed to parse ebuild via bash: %s", string(exitErr.Stderr))
		}

		return nil, errors.Wrap(err, "failed to parse ebuild via bash")
	}

	// parse the env output.
	env := map[string]string{}
	for _, line := range strings.Split(string(out), "\n") {
		if !strings.Contains(line, "=") {
			continue
		}

		parts := strings.SplitN(line, "=", 2)
		env[parts[0]] = parts[1]
	}

	eapiInt, err := strconv.Atoi(env["EAPI"])
	if err != nil {
		return nil, errors.Wrap(err, "failed to parse EAPI as an int")
	}

	if eapiInt != 8 {
		return nil, errors.Errorf("unsupported EAPI: %d", eapiInt)
	}

	// get the name and the version from the provided filename.
	dashSep := strings.Split(strings.TrimSuffix(fileName, ".ebuild"), "-")

	// name is everything before the last -
	name := strings.Join(dashSep[:len(dashSep)-1], "-")

	// version is everything after the last -
	version := strings.Join(dashSep[len(dashSep)-1:], "-")

	// create the ebuild structure from known variables.
	ebuild := &Ebuild{
		EAPI:        eapiInt,
		Name:        name,
		Version:     version,
		Description: env["DESCRIPTION"],
		License:     env["LICENSE"],
	}

	return ebuild, nil
}
