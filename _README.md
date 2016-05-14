# Usual Workflow

That's how it should be done normally.

Create:

    $ bin/newdraft.sh 'this will be my killer post'
    created: /path/to/_drafts/this-will-be-my-killer-post.md

Open draft in editor:

    $ gvim /path/to/_drafts/this-will-be-my-killer-post.md

Activate preview in browser

    $ bin/preview.sh
    # ...
    # some messages are printed...
        Server address: http://0.0.0.0:4000/
      Server running... press ctrl-c to stop.

Do your editing, occasionally refreshing the preview in the browser.

Turn draft into regular post:

    $ bin/draft2post.sh /path/to/_drafts/this-will-be-my-killer-post.md
    moved as /path/to/posts/2016-03-12-this-will-be-my-killer-post.md

Publish:

    $ bin/publish.sh
