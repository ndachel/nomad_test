Atlas Integration
=================
Up until this point, we have been running Terraform locally. This is great for
a single developer, but tends to break down in large teams. Instead, it is
recommended that you use Atlas for managing infrastructure. In addition to
running Terraform for you, Atlas has built-in ACLs, secure variable storage, and
UIs for visualizing infrastructure. Atlas is also able to integrate with GitHub
to provide first-class provenance in the system.

Remote State Setup
------------------
In order to start using this with Atlas, you will need to setup your remote
state with Atlas. If you are starting a new project, you could just use the
GitHub integration. Since we have an existing project, we have to configure the
remote state and push our current Terraform configurations to Atlas so that
Atlas can manage our resources.

First, export you Atlas token as an environment variable. Terraform reads this
environment variable to authenticate you with Atlas:

    $ export ATLAS_TOKEN="$(cat terraform.tfvars | grep atlas_token | cut -d'=' -f2 | tr -d '"' | tr -d ' ')"

The way we send our state to Atlas is via the following commands. Similar to
git, first we configure the remote:

    $ terraform remote config \
        -backend="atlas" \
        -backend-config="name=<username>/training"

Be sure to replace "<username>" with your Atlas username. This will configure
the remote state. Now we need to push our copy to Atlas:

    $ terraform remote push

Similar to `git push`, this will send our remote state to Atlas. Atlas is now
managing our remote state - this is most ideal for teams or using Atlas to run
Terraform for you (which we will do now).

Local Files Push
----------------
We could connect to GitHub, but since we have our Terraform configurations
locally, let's just upload them to Atlas now:

  $ terraform push \
      -vcs=false \
      -name="<username>/training" \
      04-atlas

Be sure to replace "<username>" with your Atlas username (the same you used
for configuring the remote state).

This will push our local Terraform files to Atlas and trigger a plan. It will
also push the local variables we have configured (such as our AWS secrets)
securely to Atlas.

We specify the `vcs=false` option because we are not using VCS (yet).

Now we can link this environment to GitHub and leverage SCM workflows for our
infrastructure! Click on "integrations" in the Atlas UI for this environment
and link to this GitHub repository under the `terraform` subdirectory.

Connecting to GitHub
--------------------
A great feature in Atlas is the ability to link an environment to a GitHub
repository. When changes are submitted to that repository (either via a change
request or via a commit to the default branch), Atlas will automatically ingress
those changes and queue a Terraform plan. If the submission is a Pull Request,
Atlas will report the status back on the GitHub page.

If you have not already done so, please sign up for a GitHub account now. Don't
worry - it's completely free for open source (which is what we are doing). Login
to github.com and create a new repo called "training". You can name it something
different, but the rest of this guide will assume the repo is called training.
Just like Atlas, everything on GitHub is namespaced under your user, so the
actual repository will be `<username>/training`. Once created, we need to
configure our local Git setup to be able to push to GitHub.

```
pushd 04-atlas
git init .
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/<username>/training.git
git push -u origin master
popd
```

Don't forget to replace `<username>` with your GitHub username. If you refresh
the page on github.com, you should see this README and your files. If you do not
see that, or if you see a list of all the different sections (such as
"01-ssh-keypair", etc), please notify the instructor before proceeding.

Now that we have pushed our code to GitHub, we need to configure Atlas to watch
our repository for changes. Login to Atlas and click on "environments" in the
main navigation bar. Next, click on the name of your environment (it should be
called "training"). Finally, click on "Integrations" on the sidebar navigation.

On the bottom of the integrations page, you will see a section for GitHub. If
this is your first time using Atlas with GitHub, you will need to authorize
Atlas to communicate with GitHub. Once you do, you will be redirected back to
Atlas and you will see a form where you can select the GitHub repository,
branch, and Terraform directory from which to pull changes.

Fill out the form, leaving the GitHub branch and Terraform directory fields
empty with their default values. Finally, click "Associate" to link the
integration. Now, any commits or Pull Requests to that repository will trigger
Terraform runs in Atlas.

You no longer need to run or manage Terraform locally. All you data is stored
and versioned securely in Atlas, backed by Vault.

Making Changes via GitHub
-------------------------
1. Click on the "README.md" file in GitHub
1. Click "edit"
1. Make any change such as adding a newline character
1. Check "Create a **new branch** for this commit"
1. Click "Propose file change"
1. Click "Create pull request"
1. Notice the yellow status icon - click on it
1. See the plan running in Atlas
1. See that the plan has no changes
1. Back in the GitHub UI, see the green checkbox
1. Merge the Pull Request
1. Go to the environment in Atlas
1. See that the merge is queuing a plan - it will have "no changes"

Making Infrastructure Changes via GitHub
-----------------------------------------
1. Edit the file "terraform/nomad.tf" and bump the `count` attribute of the
  Nomad client to 2
1. Check "Create a **new branch** for this commit"
1. Click "Propose file change"
1. Click "Create pull request"
1. Notice the yellow status icon - click on it
1. Watch the plan and look at the output
1. Notice that resources are changed, but you cannot apply it (because it is
  from a Pull Request)
1. Merge the Pull Request
1. Go to the environment in Atlas
1. See that the merge is queuing a plan - it will have changes
1. Click on the plan
1. Assuming the output looks good, click "Confirm & Apply"
1. Watch as Atlas provisions the new Nomad client for you
1. The new client will automatically join the Nomad cluster and register itself
  with the Nomad servers to start accepting work

Making Scary Changes via GitHub
-------------------------------
1. Edit the file `aws.tf` and change the name of the `aws_security_group`
1. Check "Create a **new branch** for this commit"
1. Click "Propose file change"
1. Click "Create pull request"
1. Notice the yellow status icon - click on it
1. Watch the plan and look at the output
1. Notice that a bunch of things are changing
1. Do **not** merge the Pull Request because that's scary - there are
  potentially breaking changes, and Atlas alerted you to those changes via the
  output

Tearing it all down
-------------------
1. In Atlas, click on "environments" in the header
1. Click on your environment
1. Click on settings
1. Click "Queue destroy plan" on the bottom of the page - this is just like
  any other Terraform plan in Atlas, except this will destroy the resources. You
  will still need to confirm the plan in order to apply the changes
1. Once that apply is finished, you can check in the AWS console and see that
  all the resources have been destroyed
1. Back on the settings page, you can optionally delete all of Atlas' metadata
  about the environment by clicking the red "Delete from Atlas" button
