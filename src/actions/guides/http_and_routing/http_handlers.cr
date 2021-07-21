class Guides::HttpAndRouting::HTTPHandlers < GuideAction
  ANCHOR_BUILT_IN_HANDLERS = "perma-built-in-handlers"
  guide_route "/http-and-routing/http-handlers"

  def self.title
    "HTTP Handlers"
  end

  def markdown : String
    <<-MD
    ## About handlers

    Crystal comes with a module [HTTP::Handler](https://crystal-lang.org/api/HTTP/Handler.html), which is used as middleware for your HTTP Server stack.
    These are classes you create that include the `HTTP::Handler` module to process incoming requests and return responses.

    #{permalink(ANCHOR_BUILT_IN_HANDLERS)}
    ## Built-in handlers

    Lucky comes with some built-in handlers that you can see in your `src/app_server.cr` file under the `middleware` method.
    The order of this middleware stack is the order Lucky will send a web request with the first in the stack getting the initial request, and the last finishing out the stack.

    By default when you generate a full application, your middleware stack will look like this:

    ```crystal
    def middleware : Array(HTTP::Handler)
      [
        Lucky::ForceSSLHandler.new,
        Lucky::HttpMethodOverrideHandler.new,
        Lucky::LogHandler.new,
        Lucky::ErrorHandler.new(action: Errors::Show),
        Lucky::RemoteIpHandler.new,
        Lucky::RouteHandler.new,
        Lucky::StaticCompressionHandler.new("./public", file_ext: "gz", content_encoding: "gzip"),
        Lucky::StaticFileHandler.new("./public", fallthrough: false, directory_listing: false),
        Lucky::RouteNotFoundHandler.new,
      ] of HTTP::Handler
    end
    ```

    The `request` object will start in the `Lucky::ForceSSLHandler`, do some processing, then move on to the `Lucky::LogHandler`, and so on.
    In the `Lucky::RouteHandler` it will look for a `Lucky::Action` that matches the request, run any pipes, then run the action. If no action is found,
    we check to see if there's a static file in `Lucky::StaticFileHandler`. Finally, if no route or file matches the request, we run the `Lucky::RouteNotFoundHandler`.

    ### RemoteIpHandler

    The remote IP, or remote address, is the IP address of the user on your site. Getting this value can be helpful for things like banning spammers, tracking password sharing
    with user accounts, geo locating based on IP, and many other options.

    This handler sets the `HTTP::Request#remote_address` value to the value of the first IP in the [X-Forwarded-For](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Forwarded-For)
    header, or fallback to the default `remote_address`.

    The `remote_address` method can be accessed in your actions from `context.request.remote_address`. Since this method returns `Socket::IPAddress?`, you may need to use the Crystal `try`
    method for accessing the client IP address string value.

    ```crystal
    # src/actions/home/index.cr
    class Home::Index < BrowserAction
      get "/" do
        ip_address = context.request.remote_address.try(&.address) || "N/A"

        html IndexPage, ip_address: ip_address
      end
    end
    ```

    ## Conditionally including handlers

    There may be cases where you want a handler to be included only when certain conditions are met.
    For example, let's say that we want to serve files from our `/tmp` directory in **development and test** environments, but not in production.
    This can be accomplished with a ternary statement and slight restructure of the `middleware` method in `app_server.cr`:

    ```crystal
    def middleware : Array(HTTP::Handler)
      [
        Lucky::ForceSSLHandler.new,
        Lucky::HttpMethodOverrideHandler.new,
        Lucky::LogHandler.new,
        Lucky::ErrorHandler.new(action: Errors::Show),
        Lucky::RemoteIpHandler.new,
        Lucky::RouteHandler.new,
        Lucky::StaticCompressionHandler.new("./public", file_ext: "br", content_encoding: "br"),
        Lucky::StaticCompressionHandler.new("./public", file_ext: "gz", content_encoding: "gzip"),
        Lucky::StaticFileHandler.new("./public", fallthrough: false, directory_listing: false),

        # Here is our new handler, which is `nil` when we're in production,
        # and a `StaticFileHandler` when we're in other environments.
        #
        # To make sure that `middleware` still returns only `HTTP::Handler`s,
        # we `select(HTTP::Handler)` when returning from this method.
        LuckyEnv.production? ? nil : Lucky::StaticFileHandler.new("./tmp", fallthrough: false, directory_listing: false),

        Lucky::RouteNotFoundHandler.new,
      ].select(HTTP::Handler)
    end
    ```

    ## Creating custom handlers

    Your application may have special requirements like routing legacy URLs, sending bug reporting, CORS, or even doing [HTTP Basic auth](https://en.wikipedia.org/wiki/Basic_access_authentication) while your app is in beta.
    Whatever your use case, creating a custom handler is really easy!

    First we start off by creating a new directory where we can place all of our custom handlers. Create a `src/handlers/` directory and be sure to require it `src/app.cr`.

    Next, your handler needs 3 things:
    1. It must include `HTTP::Handler`
    2. It must define a `call` method with an argument of `context : HTTP::Server::Context`
    3. It needs to call the `call_next(context)` to go to the next handler in the stack

    ```crystal
    # src/handlers/legacy_redirect_handler.cr
    class LegacyRedirectHandler
      include HTTP::Handler
      LEGACY_ROUTES = {"/old-path" => "/new-path"}

      def call(context : HTTP::Server::Context)
        if new_path = LEGACY_ROUTES[context.request.path]?
          context.response.status_code = 301
          context.response.headers["Location"] = new_path
        else
          # Go to the next handler in the stack
          call_next(context)
        end
      end
    end
    ```

    Lastly, we need to make sure our new custom handler is in our stack. Open up `src/app_server.cr` and place a new instance in the stack!

    ```crystal
    # src/app_server.cr
    #...
    class App < Lucky::BaseAppServer
      def middleware
        [
          Lucky::HttpMethodOverrideHandler.new,
          Lucky::LogHandler.new,
          LegacyRedirectHandler.new,  # Add this line
          Lucky::ErrorHandler.new(action: Errors::Show),
          Lucky::RouteHandler.new,
          Lucky::StaticFileHandler.new("./public", false),
          Lucky::RouteNotFoundHandler.new,
        ]
      end
    end
    ```

    > Note: The order of custom handlers will be completely up to you, but keep in mind the order Lucky placed the built-in handlers.
    MD
  end
end
