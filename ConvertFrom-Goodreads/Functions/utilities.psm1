filter Limit-PropertiesByFilter {
  if($_.Name -cin $filter){
    $_
  }
}

filter Limit-PropertiesByMemberType {
  if($_.MemberType -match 'Note'){$_}
}

filter Limit-PropertiesByName {
  if($_.Name -cin $frontmatter_mapping.Keys){
    $_
  }
}

$global:filter=DATA{
@(
  #from gbook
    'selfLink',
    'categories',
    'averageRating',
    'textSnippet',
    'thumbnail',
    'industryIdentifiers',
  #from openlib
    'cover_i',
    'subject',
    'lcc_sort',
    'dcc_sort',
    'ratings_average',
    'description',
    'isbn',
    'key',
  # from goodreads
    'Author',
    'Additional Authors',
    'My Rating',
    'Average Rating',
    'Publisher',
    'Number of Pages',
    'Year Published',
    'Original Publication Year',
    'Date Read',
    'Date Added',
    'Bookshelves',
    'Bookshelves with positions',
    'Exclusive Shelf',
    'Read Count',
    'Title'
  )
}

$global:booklog_content=DATA{
@"
``````dataview
TABLE WITHOUT ID
("![]("+book-cover-url+")") as "Cover",
book-title as "Title",
book-author as "Author",
book-categories as "Categories"
WHERE file = this.file
``````
---
``````dataview
TABLE WITHOUT ID
book-tags as "Status",
avg-goodreads-rating as "Avg Rating",
my-rating as "My Rating"
WHERE file = this.file
``````
---
## Notes


"@
}

$global:goodreads_url=DATA{
  "https://www.goodreads.com/book/show/"
}

$global:openlib_urls=DATA{@{
  base_url="https://openlibrary.org";
  search_api="/search.json?limit=2&page=1&offset=0&fields=key,author_name,title,editions,editions.isbn,editions.cover_i,editions.key,editions.publish_date,ratings_average,lcc_sort,dcc_sort&q=";
  isbn_api="/isbn/{ISBN}.json";
  cover_api="https://covers.openlibrary.org/b/id/"
}}

$global:gbook_search=DATA{
"https://www.googleapis.com/books/v1/volumes?fields=items(searchInfo,selfLink,volumeInfo/title,volumeInfo/*/thumbnail,volumeInfo/publishedDate,volumeInfo/authors,volumeInfo/industryIdentifiers,volumeInfo/categories,volumeInfo/averageRating,volumeInfo/description)&q="
}

$global:error_mgs=DATA{
@{
failed_logging="Couldn't start PoSh Logging Session.";
failed_outfile="[!] Couldn't write log for '{Title}'";
failed_csv_imp="Ran into an issue importing '{File}'";
failed_import="[{Complete:00.00}% Imported] Could not create a booklog for '{Title}'";
isbn=
@'


-----------------------------------
Can't find 'isbn' field for '{Title}'
[Query] {search_q}
[OpenLib_RespDeets]
{Resp}
-----------------------------------

'@;
search=
@'

-----------------------------------
Error with query: {search_q}
-----------------------------------

'@
    }
}

$global:info_msgs=DATA{
  @{
    error_item_cnt="There were {errorItemsCount} booklogs that were not created.{NewLine}";
    duration="Took {duration} to process {processed_items} item(s).";
    outfile="[{Processed:00.00}% Processed] Wrote log for '{Title}' to '{log_outpath}'.";
    start="Retrieved {TotalItems} from input, with {dupes} duplicates...will process {ToProcess} item(s).";
    dupes="Duplicate Titles:{NewLine}{DupeTitles}";
    import="[{Complete:00.00}% Imported] Created booklog object for '{Title}'";
  }
}

$global:durationfmt=DATA{"mm\m\ ss\.FF\s"}
$global:datetimefmt=DATA{ "yyyy-MM-ddTHH:mm:ss" }

$global:regex_utils=@{
  parens=[regex]::New('\([\w\W]+\)','Compiled',[timespan]::fromSeconds(3));
  pound=[regex]::New('[#]','Compiled',[timespan]::fromSeconds(3));
  pubyr=[regex]::New('[\d]{4}','Compiled',[timespan]::fromSeconds(3));
}

$global:frontmatter_mapping=DATA{
  #map booklog.metadata property names to an alias
  @{
    bkAuthors='book-authors';
    bkAvgRatings='book-ratings';
    bkCategories='book-categories';
    bkCover='book-cover-url';
    bkDescr='book-description';
    bkIdens='book-identifiers';
    bkPageCnt='book-pgcount';
    bkPubDates='book-dates';
    bkPublisher='book-publisher';
    bkStatus='book-status';
    bkTitle='book-title';
    bkURLs='book-refs';
    created='created'; 
    cssClasses='cssClasses';
    modified='modified';
    readerStats='book-stats';
    tags='tags';
  }
}