# Application Builder Proxy

The Application Builder Proxy is a thin server side component that serves two important purposes.

1. The proxy is an abstraction between Application Builder widgets and web services that are external to Engine.  Calling the proxy instead of directly calling an external web service from widgets promotes better maintainability.  For example, when an external endpoint changes only the proxy must be updated rather than the URL references in individual widgets.

2. The proxy enables client-side interaction with external services via Ajax calls in the browser. Modern browser security prevents cross site Ajax requests due to the same-origin policy.

[Watson Explorer Application Builder 11 and later includes a feature called Endpoints](http://www-01.ibm.com/support/knowledgecenter/SS8NLW_11.0.0/com.ibm.swg.im.infosphere.dataexpl.appbuilder.doc/c_de-ab-devapp-endpoints.html) which serves this purpose.  A proxy application like this one would not be needed if you are using version 11 of the software or later.


# Installing the Sample Proxy

$AB_HOME refers to the home folder for the specific Application Builder installation.  For example, on a default Windows installation, `$AB_HOME` might be C:\Program Files\IBM\WEX\AppBuilder

Create a new folder called 'proxy' in `$AB_HOME/wlp/usr/servers/AppBuilder/apps`

Unzip the proxy WAR into the newly created proxy folder.  You should now have `$AB_HOME/wlp/usr/servers/AppBuilder/apps/proxy/META-INF` and `$AB_HOME/wlp/usr/servers/AppBuilder/apps/proxy/WEB-INF`.

Open server.xml, located at $AB_HOME/wlp/usr/servers/AppBuilder/ for editing.  Add the following block to the `server` node.


```xml
   <application type="war" id="proxy" name="proxy" location="${server.config.dir}/apps/proxy">
   </application>
```


Before using the Sample Proxy it is necessary to update the proxy configuration to do something interesting.  For example, you might add functionality that points to custom [Watson Developer Cloud](https://console.ng.bluemix.net/) applications. 

Once you've modified the proxy to your liking, restart Application Builder's WebSphere according to the App Builder documentation - by restarting the Application Builder service using the normal commands for your installation.


# Usage

The sample proxy includes a single endpoint out of the box for `ping`.

```
curl http://localhost:9080/proxy/ping
```

You can also point your browser at [http://localhost:9080/proxy/ping](http://localhost:9080/proxy/ping). Change the port or hostname as appropriate specific to your sever.

Making reqests to the proxy from a widget can improve maintainability.  In the case of Ajax interactions once the page has loaded, you'll need to use the proxy to avoid violating the [same-origin request policy](https://en.wikipedia.org/wiki/Same-origin_policy) enforced by modern web browsers.

Here is an example for how to call the proxy from a Custom (ERB) widget in App Builder.  This example code calls the Ping endpoint.


```HTML+ERB
<%
require 'net/http'

# Determine the endpoint for the proxy
# This assumes that the proxy is deployed 
# to the same server as the current App Builder.

origin = URI.parse(request.original_url)
endpoint_builder = {
  :host => origin.host,
  :port => origin.port,
  :scheme => origin.scheme,
  :path => '/proxy/ping/'  
}

url = URI::HTTP.build(endpoint_builder)

response = Net::HTTP.start(url.hostname, url.port) do |http|
  req = Net::HTTP::Get.new(url.to_s)
  http.request(req)
end

response = JSON.parse(response.body)
%>

<%= response %>
```

You can also call the proxy from JavaScript in the client.  This snippet shows how you can make the same request from a browser-side Ajax call using jQuery (included by default in App Builder).  Be sure to to bind events to elements that exist in the DOM by using the standard jQuery binding methods (e.g. set your event bindings when the onLoad event is called or using delegates, etc.).


```JavaScript
$.ajax({
   type: "POST",  // all methods use POST
   url: "/proxy/ping/",
   success: function(response) {
      response = JSON.parse(response);
      console.log(response);
   },
   failure: function(error) {
      console.log(error);
   }
});
```


# Modifying the Proxy

The most common modification is to add new routes to the proxy.  As long as no new ruby gems are required it is possible to modify the proxy directly.  This can be done by updating `proxy.rb` located in `$AB_HOME/wlp/usr/servers/AppBuilder/apps/proxy/WEB-INF/lib`.

The proxy uses [Ruby Sinatra](http://www.sinatrarb.com/) to provide a REST style web service interface.  Further information on Sinatra development is [available on the web](http://www.sinatrarb.com/intro.html).

Once your changes are complete, restart Application Builder's WebSphere using the normal methods.


## Bundling a new WAR

If new gems or other Java libraries are required, or if you want to package the proxy into a new WAR for any reason, you will need to set up a basic development environment for [JRuby](http://www.jruby.org/).  Ruby was chosen for the ease of implementation (using frameworks such as Sinatra) and to allow for modifications to be made in the proxy without requiring code to be recompiled.

The proxy assumes `JRuby 1.7.18` for deployment but it might be possible to test the application in native `Ruby 1.9.3`.  The simplest approach is to use JRuby for development, testing, and deployment.

The following JRuby Gems are required to get started.

* [Bundler](http://bundler.io/)
* [Warbler](https://github.com/jruby/warbler)


First install required gems.


```
$> bundle install
```


Now the proxy can be run as a rack application for testing and development purposes.


```
$> rackup -p4567
```


At this point the proxy will be running at http://localhost:4567.

The WAR can be created using Warbler.  If adding new gems be sure that the gems are installed under JRuby and the `Gemfile` is fully up to date.  A rake task is available to Warble the proxy application.  The rake task should be used so that specific JARs required for proper operation in WebSphere are copied to the correct path locations within the generated WAR.  The rake task requires that `unzip` and `zip` are in your path.  On Linux and Mac OS these tools should be available by default.  On Windows it's simplest to run the rake task through [Git Bash](http://www.git-scm.com/), [MinGW](http://mingw.org/), or [Cygwin](https://cygwin.com/).  Another alternative on Windows is to install the [GNU Zip](http://gnuwin32.sourceforge.net/packages/zip.htm) and [Unzip](http://gnuwin32.sourceforge.net/packages/unzip.htm) utilities and use the standard CMD prompt or Powershell.  It is assumed that the Java bin folder is on your path.


```
$> rake -f warble.rake
```

There could be minor variations in the JRuby file names from one version to another.  If you run into problems running the rake task you may need to update the script based on the version of JRuby you are running.  When we moved from 1.7.13 to 1.7.18 the file names were pretty obvious and the changes trivial.  Pull requests are welcome.

# Licensing
All sample code contained within this project repository or any subdirectories is licensed according to the terms of the MIT license, which can be viewed in the file license.txt.

# Open Source @ IBM
[Find more open source projects on the IBM Github Page](http://ibm.github.io/)