## Running Haplo under Docker

[Docker](https://www.docker.com) is a popular system for running applications in containers. Here is some documentation and examples that will help you run an instance of Haplo under Docker.

### Prerequisites

First, you need to be running Docker. You can run Docker on a Linux server, either your own or in the cloud. You can also run Docker on a desktop or laptop computer running Windows or MacOS.

If you just want to run a Haplo instance, then look at the [quickstart](https://docs.haplo.org/platform/run/docker).

### Overall structure

With Docker, you run containers from images. Images are built up in layers, like an onion. The examples provided here are built in 3 layers:

 * A base Linux layer, containing an Ubuntu image with the additional packages needed by Haplo
 * A [Haplo](https://haplo.org) layer, extending the base by building and installing the Haplo stack
 * An application layer, an instance of Haplo with configuration and data

Because Docker containers are ephemeral, a Volume container is created to store persistent data.

It's also very simple to run the Haplo test suite.

### Walkthrough

First create the base image, using the Dockerfile found in haplo-base

    cd haplo-base
    docker build -t haplo-base .
    cd ..

You'll need to create the demo plugin tarball

    cd haplo-app
    ./bundle-plugins
    cp /tmp/hresrepodemo_application.tar.gz .
    cd ..

Then create the haplo image, using the Dockerfile and scripts found in haplo-app

    cd haplo-app
    docker build -t haplo-app .
    cd ..

(If you don't want the demo application, then you can safely remove the ADD line in the Dockerfile.)

Then instantiate an application. In haplo-example you will find a sample configuration, the key data you need to supply are in the file `app.values`, where you can set:

 * The URL by which the application will be accessed
 * The name of this application instance
 * The name of the first user (must contain firstname and lastname)
 * The email address of the first user, used to log in
 * A password for the first user

To use this example (you should normally copy it and use your own values)

    cd haplo-example
    docker build -t haplo-example .
    cd ..

Then create a volume container based on this configured container to persist the data you're going to store in this Haplo instance

    docker create -v /haplo --name haplo-example-db haplo-example /bin/true

To run this application, you need to run haplo-app using the data from haplo-example-db

    docker run -p 80:8080 -p 443:8443 --volumes-from haplo-example-db -it haplo-app

or, to run it disconnected in the background

    docker run -p 80:8080 -p 443:8443 --volumes-from haplo-example-db -d haplo-app

Here, we have used the -p flag to map the ports 8080 and 8443 used internally by the Haplo application to the more usual ports 80 and 443 on the Docker host. (This assumes that no other container or application is using those ports.)

To access this application, you need to either add the name you used for the URL to DNS (if running on a remote server) or edit the local hosts file (on a Mac, `sudo nano /private/etc/hosts` and add the name of your application as an alias for localhost), then point your browser at the URL and you should connect.

You can also easily run the test suite

    cd haplo-test
    docker build -t haplo-test .
    docker run haplo-test
    cd ..

###Plugin Development

Use of the [Plugin Tool](https://docs.haplo.org/dev/tool/plugin) for devlopment requires the server be run in a slightly different mode. We have a haplo-dev image with the modified configuration

    cd haplo-dev
    docker build -t haplo-dev .
    cd ..

And then `docker run haplo-dev` instead of `docker run haplo-app`.
