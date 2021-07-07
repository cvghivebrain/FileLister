# FileLister

FileLister is a command line program that lists files and their attributes in a text file.

## Usage

Drag a folder onto the batch file "DragFolderHere.bat" to list its files (including those in subfolders.

The batch file must contain the following line:

    FileLister.exe "%1" "<text file>" "<list format>"

### List format

The list format can contain any text you want, with hashtags that are replaced with file-specific information.

Hashtag | Example | Meaning
------- | ------- | -------
#name | file.exe | File name
#ext | exe | File extension
#folder | subfolder/subsubfolder/ | Subfolder path (excluding main folder)
#size | 12345 | File size in bytes
#date | 2020-12-25 | Date last modified
#created | 2005-12-25 | Creation date
#sha1 | | [SHA-1](http://en.wikipedia.org/wiki/SHA-1)
#md5 | | [MD5](http://en.wikipedia.org/wiki/MD5)
#crc32 | | [CRC32](http://en.wikipedia.org/wiki/CRC32)
#percent | % | Using this character directly breaks the batch file
#qm | " | Using this character directly breaks the batch file
\## | # | For example ##name outputs #name without replacing it with file name
