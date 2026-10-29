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

| Input               | Default                                                                 | Meaning |
|---------------------|-------------------------------------------------------------------------|---------|
| `working_directory` | repository root                                                         | Directory in which the compiler is run (and the PDF is expected). |
| `compiler`          | `latexmk`                                                               | LaTeX compiler. `latexmk` runs bibtex/biber and repeats LaTeX runs automatically. |
| `compiler_args`     | `-pdf -latexoption=-file-line-error -latexoption=-interaction=nonstopmode` | Arguments of the compiler, e.g. use `-lualatex` instead of `-pdf` or add `-shell-escape`. |
| `free_disk_space`   | `true`                                                                  | Remove unused preinstalled software from GitHub-hosted runners before building. |

The inputs `tex_command`, `bib_command`, `do_bib`, and `auxiliary_folder` are deprecated and
ignored.

## Troubleshooting

The PDF is built with the full TeX Live image of
[dante-ev/latex-action](https://github.com/dante-ev/latex-action). This image is larger than the
free disk space of GitHub's default runners, which results in errors like
`failed to register layer: ... no space left on device`. Therefore, the action first deletes
unused preinstalled software (Android SDK, .NET, GHC, ...) from the runner. Do not set
`free_disk_space: false` unless you use a self-hosted runner with enough disk space.
