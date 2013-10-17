This is the source code for the App Store distributed Raamattu+ app for iOS. It is
a simple bible reader primarily designed for reading the Finnish Bible, but,
there is nothing preventing to use the app for other languages (currently
we ship the NET translation besides the Finnish translation).

The following features have been implemented:
* Support for the iPhone/iPad UI idioms
* Localization. New localizations can be added with the standard Apple conventions.
* The bible translation can be chosen by the user when running the app
* The user can zoom the bible text with the pinch gesture
* Support for sharing the bible in social media (Facebook, Twitter, Weibo)
* Bible chapters and verses can be printed
* Full-text search from the bible
* History of the bible chapters read
* Ability to add and edit notes. Notes can be attached to bible verses
* Night mode for bible reading

![](https://raw.github.com/mobilebible/bible-ios/master/Extra/raamattu-ipad.png)

![](https://raw.github.com/mobilebible/bible-ios/master/Extra/raamattu-iphone.png)

The code can and the provided graphics assets can be freely used within
the BSD license (see the file LICENSE for more detail) but please note
that the provided app icon cannot be used as is for App Store releases.

The bible translations are SQLite FTS (Full Text Search) indexed databases.
To add a new bible translation, create a new SQLite FTS database with the
following database structure:

    CREATE TABLE book(book_num UNSIGNED INTEGER NOT NULL,
                      title VARCHAR(255) NOT NULL,
                      short_title VARCHAR(64) NOT NULL,
                      chapter_count UNSIGNED INTEGER NOT NULL,
                      PRIMARY KEY(book_num));

    CREATE VIRTUAL TABLE verse using FTS3 (book_num UNSIGNED INTEGER NOT NULL,
                                           chapter_num UNSIGNED INTEGER NOT NULL,
                                           verse_num UNSIGNED INTEGER NOT NULL,
                                           content TEXT NOT NULL,
                                           PRIMARY KEY(book_num, chapter_num, verse_num));

Register your database in MAConstants.h by creating a new translation identifier.
Modify MABookService.m (setTranslation and translationNameByIdentifier) to
register the name of your database.

For any questions, you can contact me by email at <mmu@iki.fi>
