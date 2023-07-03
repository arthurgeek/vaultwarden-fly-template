# Template for deploying [Vaultwarden] on [Fly.io]

This is a template for deploying [Vaultwarden] on [Fly.io] with
[Caddy](https://caddyserver.com) for [websockets] support and
[supercronic](https://github.com/aptible/supercronic) for hourly
[restic](https://restic.net) backups with e-mail failure notification
via [msmtp](https://marlam.de/msmtp/).

This uses a single fly machine, within Fly's [free allowance](https://fly.io/docs/about/pricing/#free-allowances).

## Usage

You first need to create a new repo for your config, by clicking
on the **Use this template** button on this page.

Then, clone your new repo and `cd` into it.

### Install dependencies

1. Install [go-task](https://github.com/go-task/task):

    We use go-task to automate some steps, you can check the task
    code under [.taskfiles](.taskfiles). to see which commands each
    task run.

    ```sh
    brew install go-task/tap/go-task
    ```

1. Install [flyctl](https://fly.io/docs/hands-on/install-flyctl/):

    ```sh
    brew install flyctl
    ```

### Configuration

The `.config.env` file contains environment variables needed to deploy
the apps in this template.

1. Copy the `.config.sample.env` to `.config.env` and fill out all
the environment variables. **All uncommented variables are required**.

### [Fly.io] setup

For some commands below, we use a task instead of `flyctl` because we
the task writes (on app creation) and reads (subsequent commands) your
app name from the config file. This is the only way to keep your app
name hidden.

1. Signup to Fly

    If you already have a Fly account, use `flyctl auth login` instead.

    ```sh
    flyctl auth signup
    ```

1. Create a new fly app

    If this is your first app, you'll be asked to add credit card
    information, but, don't worry, you'll not be charged by this app.

    ```sh
    task fly:app:create
    ```

1. Create a new volume

    This will show you a warning about invididual volumes.
    It's ok to have a single volume because we're not
    concerned about downtime for our Vaultwarden instance.

    ```sh
    task fly:volume:create
    ```

1. Deploy your app

    ```sh
    task fly:app:deploy
    ```

1. Setup your custom domain

    After your app is deployed, follow the steps [here](https://fly.io/docs/app-guides/custom-domains-with-fly/) to setup your custom domain.

1. Open your new Vaultwarden website

    That's all! Now you can open your custom domain and Vaultwarden should
    work.

## Keeping dependencies up to date

This template uses [Renovatebot](https://www.mend.io/free-developer-tools/renovate/) to scan and open new PRs when dependencies are out of date.

To enable this, open their [Github app](https://github.com/apps/renovate) page, click the "Configure" button, then choose your repo. The template already provides Renovate configs and there's no need for further action.

## Troubleshooting

If your deployment failed or you can't open Vaultwarden web, you can see
the logs with:

```sh
task fly:app:logs
```

If that command fails (eg, if the machine is stopped), try opening your
logs in the browser:

```sh
task fly:app:logs:web
```

You can also ssh in the machine with:

```sh
task fly:app:ssh
```

and check individual logs using [overmind](https://github.com/DarthSim/overmind):

```sh
# Run this command inside your fly machine
overmind connect vaultwarden
```

This will open a tmux window with vaultwarden logs.
You can scroll your tmux window with `Ctrl-B-]` and use
`Ctrl-B-D` to exit the tmux window.

Substitute `vaultwarden` with `caddy`, or `backup` to see logs for
other apps.

## FAQ

1. Why every `fly` command I run errors with: `Error: the config for your app is missing an app name`?

    For security reasons the app name is not sdaved in the [fly.toml] file.
    In that case, you have to add `-a your-app-name` to all `fly` commands.

    Your app name is found in your `.config.env` file.

    Example:

    ```sh
    fly secrets list -a your-app-name
    ```

    Or you can add:

    ```yaml
    app = "your-app-name"
    ```

    to the beginning of your [fly.toml] file.

[Vaultwarden]: https://github.com/dani-garcia/vaultwarden
[Fly.io]: https://fly.io
[websockets]: https://github.com/dani-garcia/vaultwarden/wiki/Enabling-WebSocket-notifications
[fly.toml]: fly.toml