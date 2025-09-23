---
title: Using Markdown
---
# Using Markdown

Text Pages in Writebook use <a href="https://daringfireball.net/projects/markdown/" target="_blank">Markdown</a>, a simple formatting tool for writing on the web.

If you're already a Markdown expert, you can write your book with the same formatting you're accustomed to. Below you'll find a handy reference.

But if you're new to Markdown, Writebook's text editing toolbar has the most common formatting tools for anyone who's familiar with a word processor.

 ![markdown-toolbar.png](/u/markdown-toolbar-lnzfdA.png)

When you hit a formatting button, Writebook will wrap selected text in the corresponding Markdown formatting characters.

## Basic formatting

| Markdown | Converted to HTML | Result |
|----|---|----|
| `**bold**` | `<strong>bold</strong>` | **bold** |
| `_italic_` | `<em>italic</em>` | _italic_ |
| `` `code` `` | `<code>code</code>` | `code` |
| `[link](url)` |  `<a href="url">link</a>` | [link](url) |

## Headings

Heading levels 1–6 are indicated with one or more `#` characters.
```
# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
###### Heading 6
```

# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
###### Heading 6

***

## Block quotations
Use an email style `>` to create a block quotation.

```
 > It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of light, it was the season of darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to heaven, we were all going direct the other way–in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.
```
> It was the best of times, it was the worst of times, it was the age of wisdom, it was the age of foolishness, it was the epoch of belief, it was the epoch of incredulity, it was the season of light, it was the season of darkness, it was the spring of hope, it was the winter of despair, we had everything before us, we had nothing before us, we were all going direct to heaven, we were all going direct the other way–in short, the period was so far like the present period, that some of its noisiest authorities insisted on its being received, for good or for evil, in the superlative degree of comparison only.

***


## Code blocks
Use three backticks to create a multi-line code block. Syntax highlighting is available when you specify the code language of the block.
<pre><code>``` ruby
puts 'Hello, Writebook!'  # Print out "Hello, Writebook!"
```</code></pre>

``` ruby
puts 'Hello, Writebook!'  # Print out "Hello, Writebook!"
```

## Horizontal rules
Use three asterisks (or dashes) in a row to make a horizontal rule.
```
***
```

***

## Advanced formatting

Writebook also supports `HTML` formatting in your pages. Tags like `<p>`, `<img>`, `<a>`,  `<h1>`, `<h2>`, `<strong>`, `<em>`, `<center>`, `<details>`, `<table>`, `<video>`, and more are supported. You can also use `CSS` inside the inline `style` attribute like this tip for centering text uses.

### Center text
```
<p style="text-align: center">This is centered</p>
```

<p style="text-align: center">This is centered</p>

### Open a link in a new tab/window
Use an `HTML` `a` element with the `target` attribute set to `_blank` (the preceding underscore is important) like this:

```
<a href="https://books.37signals.com" target="_blank">This opens in a new tab/window</a>
```

<a href="https://books.37signals.com" target="_blank">This opens in a new tab/window</a>


***
For a complete reference, see the official <a href="https://daringfireball.net/projects/markdown/syntax" target="_blank">Markdown Syntax</a> page.
