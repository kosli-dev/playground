
# Kosli Playground

A playground for learning how to implement [Kosli](https://kosli.com)

# Learning about Kosli

Feel free to skip this section if you are already familiar with Kosli
or want to get started straight away.

### Understanding Kosli Core Concepts
- [What are Kosli Environments and Snapshots?](docs/get_familiar.md#what-are-kosli-environments-and-snapshots)
- [What are Kosli Flows and Trails?](docs/get_familiar.md#what-are-kosli-flows-and-trails)

### Exploring real examples
- [Explore Kosli Environments and Snapshots for cyber-dojo's AWS ECS Clusters](docs/get_familiar.md#explore-kosli-environments-and-snapshots-for-cyber-dojos-aws-ecs-clusters)
- [Explore Kosli Flows and Trails for cyber-dojo's Git repos](docs/get_familiar.md#explore-kosli-flows-and-trails-for-cyber-dojos-git-repos)


# Setting up

## [Fork this repo](https://github.com/kosli-dev/playground/fork)

- Click the `Actions` tab at the top of your forked repo.
- You will see a message saying `Workflows aren’t being run on this forked repository`.
- Click the green button to enable Workflows on your forked repo.
- Please follow the remaining instructions from the README in your forked repo.
  (This is so the links correctly take you to the files in *your* repo)


## Log into Kosli at https://app.kosli.com using GitHub

Logging in using GitHub creates a Personal Kosli Organization whose name is your GitHub username.
You cannot invite other people to your personal organization; it is intended only to try Kosli out
as you are now doing. For real use you would create a Shared Kosli Organization (from the top-right 
dropdown next to your user-icon) and invite people to it.


## At https://app.kosli.com create a Docker Environment

In this playground the CI pipelines fake their deployment step by doing a "docker compose up".
Create a Kosli Environment to record what is running in this fake deployment.
- Select `Environments` from left hand side menu
- Click the blue `[Add new environment]` button at the top
- Fill in the Name field as `playground-prod`
- Check the `Docker host` radio button for the Type
- Fill in the `Description` field, eg `Learning about Kosli`
- Leave `Exclude scaling events` checked
- Leave `Compliance Calculation Require artifacts to have provenance` set to `Off`
- Click the blue `[Create environment]` button
- Open a tab in your browser for the `playground-prod` Kosli Environment as we will often review how it changes 


## Set the .env file variables

- Edit (and save) the [.env](.env) file as follows:
  - DOCKER_ORG_NAME to your GitHub username in lowercase
  - REPO_NAME (if you changed it from `playground`)

    
## Create a KOSLI_API_TOKEN and save it as a GitHub Action secret

(Note: In a Shared Organization you would do this under a Service account) 
- At https://app.kosli.com click your GitHub user icon at the top-right
- In the dropdown select `Profile`
- Click the blue `[+ Add API Key]` button
- Choose a value for the `API key expires in` or leave it as Never
- Fill in the `Description` field, eg `playground CI`
- Click the blue `[Add]` button
- You will see the api-key, something like `p1Qv8TggcjOG_UX-WImP3Y6LAf2VXPNN_p9-JtFuHr0`
- Copy this api-key (Kosli stores a hashed version of this, so it will never be available from https://app.kosli.com again).
  There is a small copy button to the right of the api-key.
- [Create a GitHub Action secret](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions#creating-secrets-for-a-repository) (at the repo level), called `KOSLI_API_TOKEN`, set to the copied value


# Understand the fake deployment in the CI pipeline

- There is a *fake* [deploy](.github/workflows/main.yml#L122) job which runs this command to bring up the container in the CI pipeline!
  ```yml
  docker compose up --wait
  ```
  After this command, the CI pipeline installs the Kosli CLI, and runs this command:
  ```yml
  kosli snapshot docker "${KOSLI_ENVIRONMENT_NAME}"
  ```
  The [kosli snapshot docker](https://docs.kosli.com/client_reference/kosli_snapshot_docker/) command takes a snapshot 
  of the Docker containers currently running (inside the CI pipeline!)
  and sends their image names and digests/fingerprints to the named Kosli Environment (`playground-prod`).
  This command does _not_ need to set the `--org`, or `--api-token` flags because
  the `KOSLI_ORG` and `KOSLI_API_TOKEN` environment variables have been set at the top of the workflow yml file.


# Make a change, run the CI workflow, review the Environment in Kosli

- Edit the file [code/alpha.rb](code/alpha.rb) so the return string from the `'/'` route is a new string
- Commit (add+commit+push if not editing in GitHub)
- Wait for the GitHub Action Workflow to complete
- Refresh your `playground-prod` Environment at https://app.kosli.com and verify it shows the `playground-alpha` 
image running. The image tag should be the short-sha of your new HEAD commit 
- This playground-alpha Artifact currently has No [provenance](https://www.kosli.com/blog/how-to-secure-your-software-supply-chain-with-artifact-binary-provenance/
) but is nevertheless showing as Compliant. This is because the Environment was set up with `Require artifacts to have provenance`=Off. 
We will provide provenance shortly.


# Make another change, rerun the CI workflow, review the Environment in Kosli

- Re-edit the file [code/alpha.rb](code/alpha.rb) so the return string from the `'/'` route is a new string
- Commit (add+commit+push if not editing in GitHub)
- Wait for the GitHub Action Workflow to complete
- Refresh your `playground-prod` Environment at https://app.kosli.com and in the [Log] view verify
  - the previous playground-alpha Artifact has exited
  - the new playground-alpha Artifact is running, and this Artifact still has No provenance


# Name your Kosli Flow and Trail

- Kosli attestations must be made against a Trail, living inside a Flow.
  - A Kosli Flow represents a business or software process for which you want to track changes and monitor compliance.
  - A Kosli Trail represents a single execution of a process represented by a Kosli Flow. 
    Each trail must have a unique identifier of your choice, based on your process and domain. 
    Example identifiers include git commits or pull request numbers.
- At the top of the [.github/workflows/main.yml](.github/workflows/main.yml) file add two new `env:` variables for the
Kosli Flow (named after your repo) and Kosli Trail (named after each git-commit), as follows:
```yml
env:
  KOSLI_FLOW: playground-alpha-ci
  KOSLI_TRAIL: ${{ github.sha }}
```


# Attest the provenance of the Artifact in the CI pipeline

- Most attestations need the Docker image digest/fingerprint. We will start by making this available to all jobs.
- In [.github/workflows/main.yml](.github/workflows/main.yml)...
  - uncomment the following comments near the top of the `build-image:` job
  ```yml
  #    outputs:
  #      artifact_digest: ${{ steps.variables.outputs.artifact_digest }}
  ```
  - uncomment the following comments at the bottom of the `build-image:` job
  ```yml
  #    - name: Make image digest available to all jobs
  #      id: variables
  #      run: |
  #        DIGEST=$(echo ${{ steps.docker_build.outputs.digest }} | sed 's/.*://')
  #        echo "artifact_digest=${DIGEST}" >> ${GITHUB_OUTPUT}
  ```
  - add the following to the end of the `build-image:` job
  to install the Kosli CLI and attest the Artifact's digest/fingerprint.
  ```yml
      - name: Setup Kosli CLI
        uses: kosli-dev/setup-cli-action@v2
        with:
          version: ${{ env.KOSLI_CLI_VERSION }}

      - name: Attest image provenance to Kosli Trail
        run: 
          kosli attest artifact "${{ needs.setup.outputs.image_name }}" 
            --artifact-type=docker
            --name=alpha
  ```
- Note that `kosli attest` commands do not need to specify the `--org` or `--flow` or `--trail` flags because there are 
environment variables called `KOSLI_ORG`, `KOSLI_FLOW`, and `KOSLI_TRAIL`.
  - In the [kosli attest artifact](https://docs.kosli.com/client_reference/kosli_attest_artifact/) command above, the 
  Kosli CLI calculates the fingerprint. To do this the CLI needs to be told
  the name of the Docker image (`${{needs.setup.outputs.image_name}}`), and that this is a Docker image
  (`--artifact-type=docker`), and that the image has previously been pushed to its registry (which it has)
  - You can also provide the fingerprint directly using the `--fingerprint` flag or `KOSLI_FINGERPRINT` environment 
    variable. 
- Commit (add+commit+push if not editing in GitHub)
- Wait for the GitHub Action Workflow to complete
- Refresh your `playground-prod` Environment at https://app.kosli.com 
- You will see a new Snapshot
- This time the Artifact will have Provenance. You can see the Flow and Trail, and also the git commit
  short-sha, and git commit message.
- In https://app.kosli.com, click `Flows` on the left hand side menu
- Click the Flow named `playground-alpha-ci`
- You should see a single Trail whose name is the repo's current HEAD commit
- Click the Trail name to view it, and confirm this Trail has a single Artifact attestation


# View a deployment diff

- Re-edit the file [code/alpha.rb](code/alpha.rb) so the return string from the `'/'` route is a new string
- Commit (add+commit+push if not editing in GitHub)
- Wait for the GitHub Action Workflow to complete
- Refresh your `playground-prod` Environment at https://app.kosli.com
- You will see a new Snapshot
- Its Artifact will have Provenance
- Click the `>` chevron to reveal more information in a drop-down
- Click the link titled `View diff` in the entry called `Previous` to see the deployment-diff; this is a diff
  (spanning potentially many commits) between the newly deployed alpha Artifact, and the previously running alpha Artifact.


# Attest unit-test evidence to Kosli

- [.github/workflows/main.yml](.github/workflows/main.yml) has a `unit-test:` job. You will attest its results to Kosli
- Add the following to the end of the `unit-test:` job to install the Kosli CLI, and attest the unit-test results
```yml
    - name: Setup Kosli CLI
      uses: kosli-dev/setup-cli-action@v2
      with:
        version: ${{ env.KOSLI_CLI_VERSION }}
          
    - name: Attest unit-test results to Kosli
      run:
        kosli attest junit --name=alpha.unit-test --results-dir=test/reports/junit
```
- Commit (add+commit+push if not editing in GitHub)
- Wait for the GitHub Action Workflow to complete
- The [kosli attest junit](https://docs.kosli.com/client_reference/kosli_attest_junit/) command
  reports the JUnit XML results files in the `--results-dir`. The alpha Artifact's tests
  are written using the Ruby MiniTest framework. Like most test frameworks, it is easy
  to output the test results in the JUnit XML format. See line 7 of [test/test_base.rb](test/test_base.rb)
- Refresh your `playground-prod` Environment at https://app.kosli.com and verify it shows the new `playground-alpha` 
image running. The image tag should be the short-sha of your new HEAD commit
- Open the latest Trail in the `playground-alpha-ci` Flow and verify
  - Its commit-sha name matches the commit in the latest `playground-prod` Snapshot
  - There is a Trail Event for the attestation called `alpha.unit-test`
  - Click the `>` chevron in this Trail Event to open its drop-down
  - Browse the JUnit results in the JSON sent by the `kosli attest junit` command
 
## Where next?

Congratulations, you've successfully instrumented a pipeline to record evidence for a software delivery process! Here's a few things that you can try now to learn some more:

- Can you make a [generic attestation](https://docs.kosli.com/client_reference/kosli_attest_generic/) to record the lint step in the pipeline?
  - Unlike the junit attestation, the Kosli CLI can't determine whether the linting is compliant, how can you record a non-compliant attestation if the linting fails?
