# GitHub Action: tex-to-pdf

GitHub action that builds and deploys a PDF to create automatically updated PDFs.

GitHub offers the opportunity to publish web pages. This can be used to publish the PDF, associated
to your tex project. If you want to publish the PDF of the latest push (or merged pull request to
the branch `main` of your repository, you can proceed as follows:

- Create a repository to contain the PDF `auto_pages` with your account. Enable the GitHub
  pages in its `Settings` and use the `main` branch to be published.

- Create a dummy GitHub account `dummy_acc` and give it write access to `auto_pages`. The email
  address with which the account ins created is `dummy_acc_mail`. Afterwards, create a personal
  access token of `dummy_acc` providing read and write access to all repositories.

- Store the personal access token as secret `CI_REPO_TOKEN` in the repository of which the PDF will
  be created.

- Add a file `tex-to-pdf.yml` to your repository's folder `.github/workflows`. This file might
  contain

```
name: "TeX to PDF"

on: push

jobs:
  make_and_deploy_pdf:
    name: Make and deploy pdf
    runs-on: ubuntu-latest
    steps:
    - name: Checkout current branch
      uses: actions/checkout@v4
      with:
        submodules: recursive
    - name: Run build and deploy action
      uses: AndreasRupp/actions@tex-to-pdf
      with:
        deploy_pdf: ${{ github.ref == 'refs/heads/main' }}
        ci_repo_token: ${{ secrets.CI_REPO_TOKEN }}
        ci_user_name: dummy_acc
        ci_user_mail: dummy_acc_mail
        pages_repo_organization: your_user_name
        pages_repo_name: auto_pages
        tex_file: main
```

where `your_user_name` is the user/organization which owns the `auto_pages` and `tex_file` is the
name of your main .tex file (without the .tex extension).

The script will then try to build the PDF on all pushes and check, whether this can be done, but
it will only be published if there is a successful push or merged pull-request to branch `main`.
Each project's PDF is stored as `<tex_file>.pdf` in `auto_pages`, so several projects can share
one pages repository (as long as their `tex_file` names differ).

## Optional inputs

| Input                  | Default                                           | Meaning |
|------------------------|---------------------------------------------------|---------|
| `working_directory`    | repository root                                   | Directory in which the compiler is run (and the PDF is expected). |
| `compiler`             | `latexmk`                                         | LaTeX compiler. `latexmk` runs bibtex/biber and repeats LaTeX runs automatically. |
| `compiler_args`        | `-pdf -file-line-error -interaction=nonstopmode`  | Arguments of the compiler, e.g. add `-shell-escape`, or use `-lualatex` or `-xelatex` (needs `collection-xetex`) instead of `-pdf`. |
| `texlive_packages`     | see below                                         | TeX Live packages, collections, or schemes to be installed. |
| `texlive_package_file` | none                                              | File in your repository listing further TeX Live packages. |
| `texlive_version`      | latest                                            | TeX Live version (year). |

The inputs `tex_command`, `bib_command`, `do_bib`, and `auxiliary_folder` are deprecated and
ignored.

## TeX Live installation

Instead of a full TeX Live (several GB), the action installs a selection of TeX Live packages with
[zauguin/install-texlive](https://github.com/zauguin/install-texlive) and caches it. The first run
(and the first run after changing the package list) takes some minutes, later runs restore the
installation from the cache within seconds. By default, the following packages are installed:

```
scheme-basic latexmk
collection-latexrecommended collection-latexextra
collection-fontsrecommended collection-mathscience collection-pictures
collection-bibtexextra biber
babel-german hyphen-german
```

If your document needs further packages, list them in a file, e.g. `.github/tl_packages`,

```
# Packages needed in addition to the default ones.
collection-publishers  # journal classes
```

and pass `texlive_package_file: .github/tl_packages` to the action. If a package is missing, the
build fails, and the action names the TeX Live package that provides the missing file.
