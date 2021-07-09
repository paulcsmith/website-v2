class Guides::GettingStarted::Configuration < GuideAction
  guide_route "/getting-started/configuration"

  def self.title
    "Configuration"
  end

  def markdown : String
    <<-MD
    ## Default Lucky environments

    Often times your configuration will change based on the environment Lucky is
    running in.

    The default environments in a Lucky app are:

    * `development`
    * `test`
    * `production`

    ## Get the current environment

    `LuckyEnv.environment` will return the currently running environment

    You can also conditionally check the environment with `LuckyEnv.development?`,
    `LuckyEnv.test?`, or `LuckyEnv.production?`

    ## Set the current environment

    `LUCKY_ENV=environment_name` to set the environment. By default it is `development`.

    ## Add custom environment

    If you need a custom environment like `staging`, for example, you can add this option in `config/env.cr`.
    This will give you the helper method `LuckyEnv.staging?` for use in your app.

    ```
    LuckyEnv.add_env :staging
    ```

    ## Configuring Lucky

    By default there are some files in the `config/` folder that are used to configure Lucky.
    Look in `config/` to configure things like server port, database host and password, etc.

    For example, to change the database config, look in `config/database.cr`.

    ## Where to put new settings

    All application configuration is found in the `config/` folder.

    If you want to add additional config, create a new file in the `config/` folder.
    Lucky will require these files for you automatically.

    ## Configuring your own code

    Lucky ships with `Habitat`. A module you can use to configure your application
    in a type safe way. For a thorough look at how to use Habitat, check out the
    [Habitat documentation](https://github.com/luckyframework/habitat#usage).

    As a quick example, if you had a class for handling payments through Stripe, you
    may want to include an API token. Here's how you would do that.

    ```crystal
    # src/models/my_stripe_processor.cr
    class MyStripeProcessor
      Habitat.create do
        setting api_token : String
      end
    end
    ```

    Then you can configure it:

    ```crystal
    # config/my_stripe_processor.cr
    MyStripeProcessor.configure do |settings|
      settings.api_token = "super secret"
    end
    ```

    ### Using ENV variables for configuration

    In reality you would likely want to use an ENV variable for this. To do that,
    add a `.env` file to your project root and change your configuration to use the
    ENV variable:

    ```bash
    # .env
    # this will be loaded in development when you call `lucky dev`
    STRIPE_API_TOKEN=123abc
    ```

    And in your config file:

    ```crystal
    # config/my_stripe_processor.cr
    MyStripeProcessor.configure do |settings|
      settings.api_token = ENV.fetch("STRIPE_API_TOKEN")
    end
    ```

    Remember to set the ENV variable in production and you'll be set!
    MD
  end
end
