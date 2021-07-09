class Guides::Frontend::AssetHandling < GuideAction
  guide_route "/frontend/asset-handling"

  def self.title
    "Asset Handling"
  end

  def markdown : String
    <<-MD
    ## Asset handling with Webpack and Laravel Mix

    By default Lucky comes set up with asset handling using Webpack through
    [Laravel Mix](https://laravel-mix.com/). Laravel Mix is a wrapper
    for common Webpack functionality that makes configuring Webpack much simpler.

    ### Why Laravel Mix instead of plain Webpack?

    Lucky uses Laravel Mix because it is very simple to configure, it's fast, and
    it works well for a lot of apps. It is also has methods for configuring
    webpack as you normally would so you have the full power of Webpack when you
    need something more complex.

    For a lot of people the default Laravel Mix setup will work out of the box, or with
    little configuration.

    > Keep in mind that Lucky does not lock you in to using webpack.
    > You can configure other build methods such as Gulp, Grunt, or your own custom at any time.

    ## Configuring Webpack

    There is a `webpack.mix.js` file in your project root. You can modify this to
    set up React, change your entry points, etc.

    Check out the [Laravel Mix documentation](https://laravel-mix.com/docs)
    for more examples of what you can do.

    ## Structuring your JavaScript

    Babel is set up so you can use new features of JavaScript.

    The entry point for JavaScript is `src/js/app.js`. You'll see that by default
    it imports Turbolinks for fast page rendering and RailsUjs to handle AJAX, links
    with PUT and DELETE requests, and a few other things. Check the
    [Turbolinks](https://github.com/turbolinks/turbolinks) and
    [RailsUjs](https://github.com/rails/jquery-ujs/wiki) docs for more info.

    Note that *RailsUjs is required* if you are rendering HTML pages in Lucky. If
    you remove it, PUT and DELETE links will no longer work correctly. You can
    safely remove Turbolinks without any problems if you don't want to use it.

    To add new JavaScript add files to `src/js/{filename}` and import them in `src/js/app.js`

    ## Structuring your CSS

    The main css file is `src/css/app.scss` and is rendered using SASS.
    Laravel Mix also sets up autoprefixer so your styles automatically have
    vendor prefixes.

    You can import other files by putting them in `src/css/*`, and importing
    them from `app.scss`. For example, you might put a component in
    `src/css/components/_btn.scss`. Remember to end the file with `.scss` so
    it's imported correctly.

    Lucky comes with some helpful plugins to make CSS a pleasure to write:

    * [Normalize.css](https://necolas.github.io/normalize.css/) for making styles consistent

    ## Removing unwanted packages

    Lucky comes with a few JavaScript and CSS packages by default. If you want to
    remove the ones you don't want, run `yarn remove {package_name}`.

    If it is a CSS or JavaScript package you may also need to remove the imports from
    `src/css/app.css` or `src/js/app.js`.

    ## Images, fonts and other assets

    You can put images, fonts and other assets in the `public/assets` folder.

    By default there is a `public/assets/images` folder, but you can add more, such
    as: `fonts`, `pdfs`, etc.

    ### Background images in CSS

    Webpack is set up to ensure your background images are present and
    fingerprinted. To have Webpack check your background images and make sure
    they are ready for caching, make sure to use relative URLs:

    ```scss
    // Webpack will find the image and rewrite the URL
    background: url("../public/assets/images/my-background.jpg")

    // Webpack will not do anything special because the path is not relative
    background: url("/images/my-background.jpg")
    ```

    ## Loading assets

    You can get a path to your assets by using the `asset` helper in pages.

    ```crystal
    # Use this in a page or component
    # Will find the asset in public/assets/images/logo.png
    img src: asset("images/logo.png")
    ```

    Note that assets are checked at compile time so if it is not found, Lucky will
    let you know. It will also let you know if you had a typo and suggest an asset
    that is close to what you typed.

    If the path of the asset is only known at runtime, you can use the `dynamic_asset`
    helper instead.

    ```crystal
    img src: dynamic_asset("images/\#{name}.png")
    ```

    ### Using assets outside of pages and components

    You can use `Lucky::AssetHelpers.asset` just about anywhere:

    ```crystal
    Lucky::AssetHelpers.asset("images/logo.png")
    ```

    ## Automatic reloading

    Lucky comes with [Browsersync](https://www.browsersync.io) hooked up. When you
    run `lucky dev` Browsersync will open a tab and automatically reload styles and
    JavaScript for you. When you change any application files the browser will
    reload once compilation has been successful.

    You can customize Browsersync in the `bs-config.js` file. You can see a list of
    [options for Browsersync](https://browsersync.io/docs/options).

    ## Asset fingerprinting

    Fingerprinting means that every asset has a special string of characters
    appended to the filename so that the browser can cache the file safely. When an
    asset changes, the fingerprint changes and the browser will use the new version.

    Make sure to use the `asset` macro to get fingerprinted assets.

    ## Asset compression

    Lucky supports static asset compression out of the box with a convenient middleware handler, `Lucky::StaticCompressionHandler`. You can add to the set of [default middleware handlers](#{Guides::HttpAndRouting::HTTPHandlers.path(anchor: Guides::HttpAndRouting::HTTPHandlers::ANCHOR_BUILT_IN_HANDLERS)}) as necessary in `src/app_server.cr`:

    ```crystal
    [
      # ...
      Lucky::StaticCompressionHandler.new("./public", file_ext: "br", content_encoding: "br"),
      Lucky::StaticCompressionHandler.new("./public", file_ext: "gz", content_encoding: "gzip"),
      # ...
    ]
    ```

    Multiple instances of the `StaticCompressionHandler` can be leveraged to permit different types of compression based on browser support. For example, the settings above would serve Brotli-compressed assets for browsers that support it, and gzipped assets for those that don't.

    ## Asset host

    Once your app is in production, you may want to serve up your assets through a
    [CDN](https://en.wikipedia.org/wiki/Content_delivery_network). To specify a different
    host, you'll use the `asset_host` option in `config/server.cr`.

    ```crystal
    # In config/server.cr
    Lucky::Server.configure do |settings|
      if LuckyEnv.production?
        settings.asset_host = "https://mycdnhost.com"
      else
        # Serve up assets locally in development and test
        settings.asset_host = ""
      end
    end
    ```

    ## Deploying to production

    If you deploy to Heroku, then you won't need to do anything. Lucky is already
    set up to build assets in production.

    If deploying outside Heroku, make sure to run `yarn prod` *before* compiling
    your project.
    MD
  end
end
