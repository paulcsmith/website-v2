class Guides::Database::Querying < GuideAction
  guide_route "/database/querying"

  def self.title
    "Querying the Database"
  end

  def markdown
    <<-MD
    ## Query Objects

    When you [generate a model](#{Guides::Database::Models.path(anchor: Guides::Database::Models::ANCHOR_GENERATE_A_MODEL)}),
    Avram will create a Query class for you in `./src/queries/{model_name}_query.cr`.
    This class will inherit from `{ModelName}::BaseQuery`. (e.g. with a `User` model you get
    a `User::BaseQuery` class).

    ```crystal
    # src/queries/user_query.cr
    class UserQuery < User::BaseQuery
    end
    ```

    Each column defined on the model will also generate methods for the query object to use.
    This gives us a type-safe way to query on each column. All of the query methods are chainable
    for both simple and more complex queries.

    ## Running Queries

    When you run any query, Avram will return an instance, array of instances, `nil`, or
    raise an exception (e.g. `Avram::RecordNotFoundError`).

    For our examples, we will use this `User` model.

    ```crystal
    class User < BaseModel
      table :users do
        # `id`, `created_at`, and `updated_at` are predefined for us
        column name : String
        column age : Int32
        column admin : Bool

        has_many tasks : Task
      end
    end
    ```

    ### Select shortcuts

    By default, all query objects include the `Enumerable(T)` module, which means methods
    like `each`, and `map` may be used.

    All query methods are called on the instance of the query object, but there's also a
    few class methods for doing quick finds.

    * `first` - Returns the first record. Raise `Avram::RecordNotFoundError` if no record is found.
    * `first?` - Returns the first record. Returns `nil` if no record is found.
    * `find(id)` - Returns the record with the primary key `id`. Raise `Avram::RecordNotFoundError` if no record is found.
    * `last` - Returns the last record. Raise `Avram::RecordNotFoundError` if no record is found.
    * `last?` - Returns the last record. Returns `nil` if no record is found.
    * `all` - Returns an array of all the records.

    ```crystal
    first_user = UserQuery.first
    last_user = UserQuery.last
    specific_user = UserQuery.find(4)
    all_users = UserQuery.all
    ```

    ### Lazy loading

    The query does not actually hit the database until a method is called to fetch a result
    or iterate over results.

    The most common methods are:

    * `first`
    * `find`
    * `each`

    For example:

    ```crystal
    # The query is not yet run
    query = UserQuery.new
    query.name("Sally")
    query.age(30)

    # The query will run once `each` is called
    # Results are not cached so a request will be made every time you call `each`
    query.each do |user|
      pp user.name
    end
    ```

    ## Simple Selects

    > When doing a `SELECT`, Avram will select all of the columns individually (i.e. `users.id,
    > users.created_at, users.updated_at, users.name, users.age, users.admin`) as opposed to `*`.
    > However, for brevity, we will use `COLUMNS`.

    ### Select all

    `SELECT COLUMNS FROM users`

    ```crystal
    users = UserQuery.new.all
    ```

    ### Select first

    `SELECT COLUMNS FROM users LIMIT 1`

    ```crystal
    # raise Avram::RecordNotFound if nil
    user = UserQuery.new.first

    # returns nil if not found
    user = UserQuery.new.first?
    ```

    ### Select last

    `SELECT COLUMNS FROM users ORDER BY users.id DESC LIMIT 1`

    ```crystal
    # raise Avram::RecordNotFound if nil
    user = UserQuery.new.last

    # returns nil if not found
    user = UserQuery.new.last?
    ```

    ### Select by primary key

    Selecting the user with `id = 3`.
    `SELECT COLUMNS FROM users WHERE users.id = 3 LIMIT 1`

    ```crystal
    # raise Avram::RecordNotFound if nil
    user = UserQuery.new.find(3)
    ```

    ### Select distinct / distinct on

    `SELECT DISTINCT COLUMNS FROM users`

    ```crystal
    UserQuery.new.distinct
    ```

    Select distinct rows based on the `name` column `SELECT DISTINCT ON (users.name) FROM users`

    ```crystal
    UserQuery.new.distinct_on(&.name)
    ```

    ## Where Queries

    The `WHERE` clauses are the most common used in SQL. Each of the columns generated by the model
    will give you a method for running a `WHERE` on that column. (e.g. the `age` can be queried using
    `age(30)` which produces the SQL `WHERE age = 30`).

    ### A = B

    Find rows where `A` is equal to `B`.

    `SELECT COLUMNS FROM users WHERE users.age = 54`

    ```crystal
    UserQuery.new.age(54)
    ```

    ### A = B AND C = D

    Find rows where `A` is equal to `B` and `C` is equal to `D`.

    `SELECT COLUMNS FROM users WHERE users.age = 43 AND users.admin = true`

    ```crystal
    UserQuery.new.age(43).admin(true)
    ```

    > All query methods are chainable!

    ### A != B

    Find rows where `A` is not equal to `B`.

    `SELECT COLUMNS FROM users WHERE users.name != 'Billy'`

    ```crystal
    UserQuery.new.name.not.eq("Billy")
    ```

    > The `not` method can be used to negate other methods like `eq`, `gt`, `lt`, and `in`.

    ### A gt/lt B

    Find rows where `A` is greater than or equal to `B`.

    `WHERE users.age >= 21`

    ```crystal
    UserQuery.new.age.gte(21)
    ```

    Find rows where `A` is greater than `B`.

    `WHERE users.created_at > '#{1.day.ago}'`

    ```crystal
    UserQuery.new.created_at.gt(1.day.ago)
    ```

    Find rows where `A` is less than or equal to `B`.

    `WHERE users.age <= 12`

    ```crystal
    UserQuery.new.age.lte(12)
    ```

    Find rows where `A` is less than `B`.

    `WHERE users.updated_at < '#{3.months.ago}'`

    ```crystal
    UserQuery.new.updated_at.lt(3.months.ago)
    ```

    ### A in / not in (B)

    Find rows where `A` is in the list `B`.

    `WHERE users.name IN ('Bill', 'John')`

    ```crystal
    UserQuery.new.name.in(["Bill", "John"])
    ```

    Find rows where `A` is not in the list `B`.

    `WHERE users.name NOT IN ('Sally', 'Jenny')`

    ```crystal
    UserQuery.new.name.not.in(["Sally", "Jenny"])
    ```

    ### A like / iLike B

    Find rows where `A` is like (begins with) `B`.

    `WHERE users.name LIKE 'John%'`

    ```crystal
    UserQuery.new.name.like("John%")
    ```

    `WHERE users.name ILIKE 'jim'`

    ```crystal
    UserQuery.new.name.ilike("jim")
    ```

    ## Ordering

    Return rows ordered by the `age` column in descending (or ascending) order.

    `SELECT COLUMNS FROM users ORDER BY users.age DESC`

    ```crystal
    UserQuery.new.age.desc_order
    # or for asc order
    UserQuery.new.age.asc_order
    ```

    ## Pagination

    To do paginating, you'll use a combination of limit and offset. You can also use this formula to help.

    ```crystal
    page = 1
    per_page = 12

    limit = per_page
    offset = per_page * (page - 1)

    UserQuery.new.limit(limit).offset(offset)
    ```

    ### Limit

    `SELECT COLUMNS FROM users LIMIT 1`

    ```crystal
    UserQuery.new.limit(1)
    ```

    ### Offset

    `SELECT COLUMNS FROM users OFFSET 20`

    ```crystal
    UserQuery.new.offset(20)
    ```

    ## Aggregates

    ### Count

    `SELECT COUNT(*) FROM users`

    ```crystal
    total_count = UserQuery.new.select_count
    ```

    ### Avg / Sum

    `SELECT AVG(users.age) FROM users`

    ```crystal
    UserQuery.new.age.select_average
    ```

    `SELECT SUM(users.age) FROM users`

    ```crystal
    UserQuery.new.age.select_sum
    ```

    ### Min / Max

    `SELECT MIN(users.age) FROM users`

    ```crystal
    UserQuery.new.age.select_min
    ```

    `SELECT MAX(users.age) FROM users`

    ```crystal
    UserQuery.new.age.select_max
    ```

    ## Associations and Joins

    When you have a model that is associated to another, your association is a method you can use
    to return those records.

    ### Associations

    Each association defined on your model will have a method that takes a block, and passed in the
    query for that association.

    You can use this to help refine your association.

    ```crystal
    UserQuery.new.join_tasks.tasks { |task_query|
      # WHERE tasks.title = 'Clean up notes'
      task_query.title("Clean up notes")
    }
    ```

    This will return all users who have a task with a title "Clean up notes". You can continue to scope
    this on both the `User` and `Task` side.

    > This example shows the `has_many` association, but all associations including `has_one`, and
    > `belongs_to` take a block in the same format.

    ### Inner joins

    `SELECT COLUMNS FROM users INNER JOIN tasks ON users.id = tasks.user_id`

    ```crystal
    UserQuery.new.join_tasks
    ```

    > By default the `join_{{association_name}}` method will be an `INNER JOIN`, but you can also
    > use `inner_join_{{association_name}}` for clarity

    ### Left joins

    `SELECT COLUMNS FROM users LEFT JOIN tasks ON users.id = tasks.user_id`

    ```crystal
    UserQuery.new.left_join_tasks
    ```

    ## Preloading

    In development and test environemnts Lucky requries preloading associations. If you forget to preload an
    association, a runtime error will be raised when you try to access it. In production, the association will
    be lazy loaded so that users do not see errors.

    This solution means you will find N+1 queries as you develop instead of in productionm and users will never
    see an error.

    To preload, just call `preload_{association name}` on the query:

    ```crystal
    UserQuery.new.preload_tasks
    ```

    ### Customizing how associations are preloaded

    Sometimes you want to order preloads, or add where clauses. To do this, use the
    `preload_{{association_name }}` method on the query, and pass a query object for the association.

    ```crystal
    UserQuery.new.preload_tasks(TaskQuery.new.completed(false))
    ```

    This is also how you would do nested preloads:

    ```crystal
    # Preload the users's tasks, and the tasks's author
    UserQuery.new.preload_tasks(TaskQuery.new.preload_author)
    ```

    > Note that you can only pass query objects to `preload` if the association is defined, otherwise you will
    > get a type error.

    ### without preloading

    Sometimes you have a single model and don’t need to preload items. Or maybe you *can’t* preload because the
    model record is already loaded. In those cases you can use the association name with `!`:

    ```crystal
    task = TaskQuery.first
    # Returns the associated author and does not trigger a preload error
    task.user!
    ```

    ## No results

    Avram gives you a `none` method to return no results. This can be helpful when under
    certain conditions you want the results to be empty.

    ```crystal
    UserQuery.new.none
    ```

    > This method does not return an empty array immediately. You can still chain other query methods,
    > but it will always return no records. For example: `UserQuery.new.none.first` will never return a result

    ## Named Scopes

    Chaining multiple query methods can be hard to read, tedious, and error prone. If you are making a
    complex query more than once, or want to give a query a label, named scopes are a great alternative.

    ```crystal
    class UserQuery < User::BaseQuery
      def adults
        age.gte(18)
      end

      def search(name)
        ilike("\#{name}%")
      end
    end

    UserQuery.new.adults.search("Sal")
    ```

    ### Using with associations

    ```crystal
    class UserQuery < Uery::BaseQuery
      def recently_completed_admin_tasks
        admin(true)
          .join_tasks
          .tasks { |task_query|
            task_query
              .completed(true)
              .updated_at.gte(1.day.ago)
          }
      end
    end

    # Then to use it
    UserQuery.new.recently_completed_admin_tasks
    ```

    > Since associations take a block, you can also use [Short one-argument syntax](https://crystal-lang.org/reference/syntax_and_semantics/blocks_and_procs.html#short-one-argument-syntax).
    > (e.g. `tasks(&.completed(true).updated_at.get(1.day.ago))`)

    ## Deleting Records

    ### Delete one

    Deteling a single record is actually done on the [model]() directly. Since each query returns an
    instance of the model, you can just call `delete` on that record.

    ```crystal
    user = UserQuery.find(4)

    # DELETE FROM users WHERE users.id = 4
    user.delete
    ```

    ### Delete all

    If you need to just delete every record in the entire table, you can use `destroy_all` to truncate.

    `TRUNCATE TABLE users`

    ```crystal
    UserQuery.new.destroy_all
    ```

    > This method is not chainable, and may be renamed in the future.

    ## Complex Queries

    If you need more complex queries that Avram may not support, you can run
    [raw SQL](#{Guides::Database::RawSql.path}).

    > Avram is designed to be type-safe. You should use caution when using the non type-safe methods,
    > or raw SQL.

    ## Debugging Queries

    Sometimes you may need to double check that the query you wrote outputs the SQL you expect.
    To do this, you can use the `to_sql` method which will return an array with the query, and args.

    ```crystal
    UserQuery.new
      .name("Stan")
      .age(45)
      .limit(1)
      .to_sql #=> ["SELECT COLUMNS FROM users WHERE users.name = $1 AND users.age = $2 LIMIT $3", "Stan", 45, 1]
    ```
    MD
  end
end
