class Guides::Database::DeletingRecords < GuideAction
  ANCHOR_SOFT_DELETE = "perma-soft-delete"
  guide_route "/database/deleting-records"

  def self.title
    "Deleting records"
  end

  def markdown : String
    <<-MD
    ## Delete Operations

    Similar to the `SaveOperation`, Avram comes with a `DeleteOperation` that's generated with each model.
    This allows you to write more complex logic around deleteing records. (e.g. delete confirmations, etc...)

    ### Simple deletes

    If you just want to delete a record without any validations or callbacks, the simplest way is to use the generated `{ModelName}::DeleteOperation`

    For example, if we have a `Server` model, Lucky will generate a `Server::DeleteOperation` that you can use:

    ```crystal
    server = ServerQuery.find(123)
    Server::DeleteOperation.destroy!(server)
    ```

    If the record fails to be deleted, an `Avram::InvalidOperationError` will be raised.

    ### Setting up a custom DeleteOperation

    You can customize DeleteOperations with callbacks and validations.  These
    classes go in your `src/operations/` directory, and will inherit from
    `{ModelName}::DeleteOperation`.

    ```crystal
    # src/operations/delete_server.cr
    class DeleteServer < Server::DeleteOperation
    end
    ```

    ### Using a `DeleteOperation` in actions

    The interface should feel pretty familiar. The object being deleted is passed in to the `destroy` method, and a block will
    return the operation instance, and the object being deleted.

    > Note: The second block argument (the deleted object) is optional

    ```crystal
    # src/actions/servers/delete.cr
    class Servers::Delete < BrowserAction
      delete "/servers/:server_id" do
        server = ServerQuery.find(server_id)

        # The second block argument can be completely removed.
        # It is shown here with a `_` to show that it can be used if needed.
        DeleteServer.destroy(server) do |operation, _deleted_server|
          if operation.deleted?
            redirect to: Servers::Index
          else
            flash.danger = "Could not delete"
            html Servers::EditPage, server: server
          end
        end
      end
    end
    ```

    You can also pass in params or named args for use with attributes, or `needs`.

    ```crystal
    DeleteServer.destroy(server, params, secret_codes: [23_u16, 94_u16]) do |operation, deleted_server|
      if operation.deleted?
        redirect to: Servers::Index
      else
        flash.danger = "Could not delete"
        html Servers::EditPage, server: deleted_server
      end
    end
    ```

    ### Destroy and raise if it fails

    You can also use the `destroy!` method if you don't need validations and expect delete's to work every time:

    ```crystal
    DeleteServer.destroy!(server)
    ```

    This is helpful when your operation only has callbacks or needs and is expected to work every time.

    ## `DeleteOperation` Callbacks and Validations

    DeleteOperations come with `before_delete` and `after_delete` callbacks that allow you to either validate
    some code before performing the delete, or perform some action after deleteing. (i.e. Send a "Goodbye" email, etc...)

    Along with the callbacks, you also have access to `attribute`, `needs`, and all of the columns related to a model.
    You even have `file_attribute` for those times you need to use biometric scans to authorize deleting a record!

    ### before_delete

    ```crystal
    # src/operations/delete_server.cr
    class DeleteServer < Server::DeleteOperation
      attribute confirmation : String

      before_delete do
        validate_required confirmation

        # `record` is the object to be deleted
        if confirmation.value != record.server_name
          confirmation.add_error("Confirmation must match the server name")
        end
      end
    end
    ```

    ### after_delete

    ```crystal
    # src/operations/delete_server.cr
    class DeleteServer < Server::DeleteOperation
      needs secret_codes : Array(UInt16)

      after_delete do |deleted_server|
        decrypted_server_data = DecryptServer.new(deleted_server, with: secret_codes)

        DecryptedServerDataEmail.new(decrypted_server_data).deliver
      end
    end
    ```

    ### Bulk delete

    > Currently bulk deletes with DeleteOperation are not supported.

    If you need to bulk delete a group of records based on a where query, you can use `delete` at the end of your query.
    This returns the number of records deleted.

    ```crystal
    # DELETE FROM users WHERE banned_at IS NOT NULL
    UserQuery.new.banned_at.is_not_nil.delete
    ```

    #{permalink(ANCHOR_SOFT_DELETE)}
    ## Soft Deletes

    A "soft delete" is when you want to hide a record as if it were deleted, but you want to keep the actual
    record in your database. This allows you to restore the record without losing any previous data or associations.

    Avram comes with some built-in modules to help make working with soft deleted records a lot easier. Let's add it
    to an existing `Article` model.

    * First, we need to add a new `soft_deleted_at : Time?` column to the table that needs soft deletes.

    ```
    # Run this in your terminal
    lucky gen.migration AddSoftDeleteToArticles
    ```

    * Open your new `db/migrations/#{Time.utc.to_s("%Y%m%d%H%I%S")}_add_soft_delete_to_articles.cr` file.

    ```crystal
    def migrate
      alter table_for(Article) do
        add soft_deleted_at : Time?
      end
    end
    ```

    * Now open your `src/models/article.cr` file.

    ```crystal
    class Article < BaseModel
      # Include this module to add methods for
      # soft deleting and restoring
      include Avram::SoftDelete::Model

      table do
        # Add the new column to your model
        column soft_deleted_at : Time?
      end
    end
    ```

    * Next you need to update `src/queries/article_query.cr`.

    ```crystal
    class ArticleQuery < Article::BaseQuery
      # Include this module to add methods for
      # querying and soft deleting records
      include Avram::SoftDelete::Query
    end
    ```

    ### Marking a record as soft deleted

    Once a model includes the `Avram::SoftDelete::Model`, the associated DeleteOperation will handle the soft delete for you.

    ```crystal
    # src/operations/delete_article.cr
    class DeleteArticle < Article::DeleteOperation
    end
    ```

    and in your action

    ```crystal
    # src/actions/articles/delete.cr
    class Articles::Delete < BrowserAction
      delete "/articles/:article_id" do
        article = ArticleQuery.find(article_id)

        deleted_article = DeleteArticle.destroy!(article)

        # This returns `true`
        deleted_article.soft_deleted?

        redirect to: Articles::Index
      end
    end
    ```

    ### Soft deleting in bulk

    > Currently bulk soft deletes with DeleteOperation are not supported.

    You can bulk update a group of records as soft deleted with the `soft_delete` method on your Query object.

    ```crystal
    articles_to_delete = ArticleQuery.new.created_at.gt(3.years.ago)

    # Marks the articles created over 3 years ago as soft deleted
    articles_to_delete.soft_delete
    ```

    ### Restore a soft deleted record

    If you need to restore a soft deleted record, you can use the `restore` method on the model instance.

    ```crystal
    # Set the `soft_deleted_at` back to `nil`
    article.restore
    ```

    ### Bulk restoring soft deleted records

    The same as we can bulk soft delete records, we can also bulk update to restore them with
    the `restore` method on your Query object.

    ```crystal
    articles_to_restore = ArticleQuery.new.published_at.lt(1.week.ago)

    # Restore recently published articles
    articles_to_restore.restore
    ```

    ### Query soft deleted records

    ```crystal
    # Return all articles that are not soft deleted
    ArticleQuery.new.only_kept

    # Return all articles that are soft deleted
    ArticleQuery.new.only_soft_deleted
    ```

    ### Default queries without soft deleted

    If you want to filter out soft deleted records by default, it's really easy to do.
    Just add the `only_kept` method as the default query in the `initialize` method.

    ```crystal
    class ArticleQuery < Article::BaseQuery
      include Avram::SoftDelete::Query

      # All queries will scope to only_kept
      def initialize
        defaults &.only_kept
      end
    end
    ```

    ```crystal
    # Return all articles that are not soft deleted
    ArticleQuery.new
    ```

    Even with your default scope, you can still return soft deleted records when you need.

    ```crystal
    # Return all articles, both `kept` and soft deleted
    ArticleQuery.new.with_soft_deleted
    ```

    ## Truncating

    ### Truncate table

    If you need to delete every record in the entire table, you can use `truncate`.

    `TRUNCATE TABLE users`

    ```crystal
    UserQuery.truncate
    ```

    ### Truncate database

    You can also truncate your entire database by calling `truncate` on your database class.

    ```crystal
    AppDatabase.truncate
    ```

    > This method is great for tests; horrible for production. Also note this method is not chainable.
    MD
  end
end
