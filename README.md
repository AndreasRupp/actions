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
    runs-on: ubuntu-20.04
    steps:
    - name: Checkout current branch
      uses: actions/checkout@v2
      with:
        submodules: recursive
    - name: Run build and deploy action
      uses: AndreasRupp/actions@tex-to-pdf
      with:
        deploy_pdf: ${{ github.ref == 'refs/heads/main' }}
        tex_command: "pdflatex"
        bib_command: "bibtex"
        ci_repo_token: ${{ secrets.CI_REPO_TOKEN }}
        ci_user_name: dummy_acc
        ci_user_mail: dummy_acc_mail
        pages_repo_organization: your_user_name
        pages_repo_name: auto_pages
        tex_file: main
```

where `your_user_name` is the user/organization which owns the `auto_pages`, `pdflatex` is the
command which builds the PDF if you are in the main directory of the rspository, and the 
`tex_file` is the name of your main .tex file (without the .tex extension).

The script will then try to build the PDF on all pushes and check, whether this can be done, but
it will only be published if there is a successful push or merged pull-request to branch `main`.
