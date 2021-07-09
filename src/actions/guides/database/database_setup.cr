class Guides::Database::DatabaseSetup < GuideAction
  ANCHOR_SEEDING_DATA       = "perma-seeding-data"
  ANCHOR_MULTIPLE_DATABASES = "perma-multiple-databases"
  guide_route "/database/database-setup"

  def self.title
    "Database Setup"
  end

  def markdown : String
    <<-MD
    ## Configure

    Ensure that your system is running a [PostgreSQL](https://www.postgresql.org/docs/current/tutorial-install.html) version of at least 9.4 or later.

    > If you're using the postgres app on macOS, be sure to install [CLI tools](https://postgresapp.com/documentation/cli-tools.html).

    ### Avram Configuration

    Avram comes with an `Avram::Credentials` class for configuring your database credentials. This helps to catch incorrect settings at compile-time
    like malformatted usernames and such.

    To configure Lucky to connect to your database, open up your `config/database.cr` file. You'll find a few options within the `AppDatabase` configure block.

    ### Standard Options

    Set the `settings.credentials` to `Avram::Credentials.new` and pass in these options:

    * database : `String` - This is the name of your database. The default is set at the top of this file.
    * hostname : `String?` - The host where your database is located. Generally "localhost".
    * username : `String?` - Your database user.
    * password : `String?` - Your password.
    * port : `Int32?` - The port to connect to. Default is `5432`
    * query : `String?` - A query string of connection pool settings.

    ```crystal
    # config/database.cr
    AppDatabase.configure do |settings|
      settings.credentials = Avram::Credentials.new(
        database: database_name,
        hostname: "localhost",
        port: 5432,
        username: "postgres",
        query: "initial_pool_size=5&retry_attempts=2"
      )
    end
    ```

    On most systems, you can leave the password blank if your setup doesn't require a password. If you wish to use password-less connections for local development,
    and leaving the password blank doesn't work, please see [Installing Postgres](#{Guides::GettingStarted::Installing.path(anchor: Guides::GettingStarted::Installing::ANCHOR_POSTGRESQL)})
    for more tips.

    ### Using Postgres connection string

    Avram also supports using a standard connection string whether you want to use unix sockets or connect with credentials. For this, we can just set
    the environment variable `DATABASE_URL` (defined in `config/database.cr`) and parse it with `Avram::Credentials.parse`.

    ```crystal
    # This will raise an exception if `DATABASE_URL` is missing, or formatted incorrectly
    settings.credentials = Avram::Credentials.parse(ENV["DATABASE_URL"])

    # Note the use of "?". This will return nil if `DATABASE_URL` is missing.
    settings.credentials = Avram::Credentials.parse?(ENV["DATABASE_URL"]?)
    ```

    You can set this value in your `.env` file.

    ```
    # Define your connection string
    DATABASE_URL=postgres://myuser:somepass@localhost:5432/my_db?retry_attempts=2

    # Or use a local unix socket
    DATABASE_URL=postgres:///my_db
    ```

    ### Connection Pool

    Lucky also supports connection pool settings:

    * initial_pool_size
    * max_pool_size
    * max_idle_pool_size
    * checkout_timeout
    * retry_attempts
    * retry_delay

    To set the connection pool options, just set the `query` option in your `Avram::Credentials` to a query string.
    (e.g. `query: "initial_pool_size=5&max_pool_size=10"`).

    > If using a connection string, set the query at the end.
    > (e.g. `postgres://postgres@localhost/my_db?initial_pool_size=5`)

    ### Other Avram Options

    Optionally, the `lazy_load_enabled` is set to `false` for development and test.
    This causes Lucky to raise an exception if you forget to preload an association,
    but will not raise an exception in production.

    ```crystal
    settings.lazy_load_enabled = LuckyEnv.production?
    ```

    ### Apps not using Avram

    Avram requires a `credentials` option to be set. If you decide to not use Avram as your ORM,
    you can set this option to `Avram::Credentials.void`.

    ```crystal
    # An example can be found on this website's source
    # https://github.com/luckyframework/website/blob/master/config/database.cr
    AppDatabase.configure do |settings|
      # No database is required
      settings.credentials = Avram::Credentials.void
    end

    Avram.configure do |settings|
      settings.database_to_migrate = AppDatabase
    end
    ```

    ## Test Setup

    If you'd like to use separate credentials for your testing database, you can add
    another conditional in `config/database.cr` that checks for `LuckyEnv.test?` and
    sets the `setting.url` option to the appropriate value.

    ## Create and Drop database

    ### Create database

    To create your database, run the `lucky db.create` task. This will create the database
    named from `database_name` in your `config/database.cr` file.

    You can also run `lucky db.setup` to both create, and [migrate](#{Guides::Database::Migrations.path})
    your database in one task.

    ### Drop database

    To drop the database, run the `lucky db.drop`

    > Please *please* don't ever do this in production

    #{permalink(ANCHOR_SEEDING_DATA)}
    ## Seeding Data

    Seeding is the process of putting data in to your database. This could be fake placeholder
    data you use in development, or even special data your application expects to exist in production.

    By default, Lucky generates two tasks in your app's `tasks/` folder. `Db::Seed::RequiredData`,
    and `Db::Seed::SampleData`. You can use [Factories](#{Guides::Testing::CreatingTestData.path}) or [Operations](#{Guides::Database::SavingRecords.path}) to create the data.

    ### Required Seeds

    Let's say you're getting ready to launch your application to production for the very first time.
    You may need an initial Admin user account that will be able to login and create your other Admin accounts.

    This code will go in `tasks/seed/db/required_data.cr`.

    ```crystal
    def call
      # Using a Factory
      UserFactory.create &.email("developer@example.com").admin(true)

      # Using an Operation
      SaveUser.create!(email: "developer@example.com", admin: true)
    end
    ```

    Run this task with `lucky db.seed.required_data`.

    > This task should be ran after your first deployment, and whenever your seeds change.
    > Running `./script/setup` will run the `db.seed.required_data` task for you.

    ### Sample Seeds

    This data is a great way to fill your development database with fake placeholder data
    to mimic a fully functioning production database without the worry of losing production data.

    This code will go in `tasks/db/seed/sample_data.cr`.

    ```crystal
    def call
      # Using a Factory
      100.times do
        ProductFactory.create
      end

      # Using an Operation
      100.times do |i|
        SaveProduct.create!(name: "Product \#{i}")
      end
    end
    ```

    Run this task with `lucky db.seed.sample_data`.

    > Running `./script/setup` in development will run the `db.seed.sample_data` task for you.
    > If you need to re-seed, you can run `lucky db.drop` and then `./script/setup` to re-create
    > and seed your local database.

    #{permalink(ANCHOR_MULTIPLE_DATABASES)}
    ## Multiple Databases

    Avram supports a multi-database setup which you may need to use for connecting to a legacy
    db, or maybe doing a read/write replica setup.

    By default, Lucky gives you the `AppDatabase` class for your primary DB. To add a second one,
    you'll need to create a new class and inherit from `Avram::Database`.

    ```crystal
    # src/secondary_database.cr
    class SecondaryDatabase < Avram::Database
    end
    ```

    Then require the file in `src/app.cr`:

    ```crystal
    # Add this right above the `require "./app_database.cr"`
    require "./secondary_database.cr"
    ```

    Next, you'll need to add the connection info for the `SecondaryDatabase`.

    ```crystal
    # config/database.cr
    SecondaryDatabase.configure do |settings|
      settings.credentials = Avram::Credentials.parse?(ENV["SECOND_DATABASE_URL"]?) || Avram::Credentials.new(
        database: "db_two",
        hostname: "localhost",
        username: "postgres",
        password: "postgres"
      )
    end
    ```

    Lastly, any models that need to use this database will need to define a class
    method `def self.database` with the database.

    ```crystal
    # src/models/legacy_user.cr
    class LegacyUser < Avram::Model
      table :users do
      end

      def self.database
        SecondaryDatabase
      end
    end
    ```

    If you have many models that require connection to the `SecondaryDatabase`, you can
    make a `SecondaryBaseModel` class in `src/models/secondary_base_model.cr` and have
    those models inherit from that class.

    ```crystal
    # src/models/secondary_base_model.cr
    abstract class SecondaryBaseModel < Avram::Model
      def self.database : Avram::Database.class
        SecondaryDatabase
      end
    end
    ```

    Require it in `src/app.cr`:

    ```crystal
    # Add this right above the `require "./models/base_model.cr"`
    require "./secondary_base_model.cr"
    ```

    Models can now inherit from this class:

    ```crystal
    class LegacyUser < SecondaryBaseModel
    end
    ```


    > Note: migrations are ran against the `AppDatabase`. If you need to run migrations against
    > another database, you'll need to update the `database_to_migrate` option in `config/database.cr`
    MD
  end
end
