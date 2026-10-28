# Publishing to GitHub

The GitHub connector used in the planning chat cannot create a new repository; this scaffold contains a reproducible publisher for your local machine.

On Arch Linux:

```bash
sudo pacman -S --needed git github-cli
gh auth login
cd relproof
bash scripts/publish.sh
```

The script creates a **private** `gqgs/relproof` repo, pushes the scaffold, creates three issue labels, and publishes all eleven backlog issues. It is designed to skip issues whose titles already exist on rerun. It requires you to have a GitHub account with permission to create `gqgs` repos, and Git commit identity configured.

To change the target or visibility:

```bash
REPO=your-org/relproof VISIBILITY=public bash scripts/publish.sh
```

GitHub issue files are also readable offline under `issues/`.
