# PDF/PPT Support & Enhanced Context Retrieval for Writebook

## Executive Summary

This document outlines the implementation plan for adding PDF and PowerPoint support to Writebook, along with enhanced context retrieval capabilities using vector embeddings or improved search indexing. The goal is to allow users to import document formats and enable the AI assistant to intelligently reference content across sections of a book.

## Current State Analysis

### Existing Architecture

**Content Model:**
- Books contain Leaves (polymorphic containers)
- Leaf types: `Page` (markdown), `Section` (styled text), `Picture` (image + caption)
- Content stored via `ActionText::Markdown` for Pages
- Full-text search via SQLite FTS5 (`leaf_search_index` table)

**AI Integration:**
- `FileAnalyzerAgent` - handles image analysis (working) and PDF analysis (placeholder)
- `WritingAssistantAgent` - writing improvement with streaming
- `ResearchAssistantAgent` - web research with browser tools
- Context persistence via `SolidAgent` concern

**Current Limitations:**
- PDF extraction in `FileAnalyzerAgent` is a placeholder
- No PowerPoint support
- No cross-section context retrieval for AI
- Search is keyword-based (FTS5), not semantic

---

## Part 1: PDF/PPT Support

### Option A: Convert to Images for LLM Vision Analysis

**Approach:** Convert PDF/PPT pages to images and use GPT-4o's vision capabilities.

**Pros:**
- Preserves layout, formatting, charts, diagrams
- Works with scanned/image-based PDFs
- Leverages existing `FileAnalyzerAgent` image analysis
- No need to handle complex document parsing

**Cons:**
- Higher token cost (images are expensive)
- Limited to ~20 pages efficiently per context window
- Can't copy/paste text from the analysis
- Storage overhead for generated images

**Implementation:**
```ruby
# New gems required
gem 'pdf-reader'      # Already in Gemfile
gem 'mini_magick'     # Or 'vips' for image processing
gem 'ruby-pptx'       # For PowerPoint parsing
```

```ruby
# app/services/document_to_images_service.rb
class DocumentToImagesService
  def initialize(file_path)
    @file_path = file_path
  end

  def convert_pdf
    # Use poppler-utils (pdftoppm) or ImageMagick
    # Convert each page to PNG
    images = []
    # ... implementation
    images
  end

  def convert_pptx
    # Extract slides as images using LibreOffice headless
    # or parse XML and render
  end
end
```

### Option B: Store and Render PDFs Natively (Recommended)

**Approach:** Store PDFs as attachments, render in browser via PDF.js, extract text for search/AI.

**Pros:**
- Native PDF viewing experience
- Searchable text extraction
- Lower storage than image conversion
- Can provide specific pages as context to LLM

**Cons:**
- More complex implementation
- Requires PDF.js integration
- PPT still needs conversion

**Implementation:**

#### 1. New Leafable Type: `Document`

```ruby
# app/models/document.rb
class Document < ApplicationRecord
  include Leafable

  has_one_attached :file

  # Extracted text from each page, stored as JSON
  # { "1": "text from page 1", "2": "text from page 2", ... }
  store :page_text, coder: JSON

  # Total page count
  attribute :page_count, :integer, default: 0

  # Document type: pdf, pptx, docx
  attribute :document_type, :string

  after_create_commit :extract_text_async

  def searchable_content
    page_text.values.join("\n")
  end

  def text_for_pages(range)
    range.map { |n| page_text[n.to_s] }.compact.join("\n\n")
  end

  private

  def extract_text_async
    DocumentTextExtractionJob.perform_later(self)
  end
end
```

#### 2. Migration

```ruby
# db/migrate/xxx_create_documents.rb
class CreateDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :documents do |t|
      t.json :page_text, default: {}
      t.integer :page_count, default: 0
      t.string :document_type
      t.timestamps
    end
  end
end

# Update Leafable TYPES
# TYPES = %w[ Page Section Picture Document ]
```

#### 3. Text Extraction Service

```ruby
# app/services/pdf_text_extractor.rb
class PdfTextExtractor
  def initialize(file_path)
    @reader = PDF::Reader.new(file_path)
  end

  def extract
    pages = {}
    @reader.pages.each_with_index do |page, index|
      pages[(index + 1).to_s] = page.text
    end
    { page_count: @reader.page_count, pages: pages }
  end
end
```

#### 4. PDF Viewer Component (Stimulus + PDF.js)

```javascript
// app/javascript/controllers/pdf_viewer_controller.js
import { Controller } from "@hotwired/stimulus"
import * as pdfjsLib from 'pdfjs-dist'

export default class extends Controller {
  static values = { url: String, page: Number }

  async connect() {
    const pdf = await pdfjsLib.getDocument(this.urlValue).promise
    this.renderPage(this.pageValue || 1)
  }

  async renderPage(num) {
    const page = await this.pdf.getPage(num)
    const canvas = this.element.querySelector('canvas')
    // ... render logic
  }
}
```

### Option C: Hybrid Approach (Best of Both)

**Approach:** Store original PDF, extract text for search, generate page images on-demand for LLM vision analysis.

This is the recommended approach as it provides:
1. Native PDF viewing
2. Full-text search capability
3. Vision analysis when text extraction is poor (scanned PDFs)
4. Flexibility in how context is provided to LLM

---

## Part 2: Enhanced Context Retrieval for AI

The goal is to allow the AI assistant to intelligently reference other sections from the same book when helping with writing tasks.

### Option A: Vector Embeddings (Semantic Search)

**Approach:** Generate embeddings for each page/section and use similarity search.

**Pros:**
- Semantic understanding (finds related content even without keyword match)
- Better for finding conceptually related sections
- Industry standard for RAG applications

**Cons:**
- Requires embedding model (OpenAI, local model, etc.)
- Additional infrastructure (vector database or SQLite extension)
- Cost per embedding generation
- More complex implementation

**Implementation with SQLite-VSS (Vector Similarity Search):**

```ruby
# Gemfile
gem 'sqlite-vss'  # SQLite extension for vector search
```

```ruby
# db/migrate/xxx_create_leaf_embeddings.rb
class CreateLeafEmbeddings < ActiveRecord::Migration[8.0]
  def change
    # Using sqlite-vss extension
    execute <<-SQL
      CREATE VIRTUAL TABLE leaf_embeddings USING vss0(
        embedding(1536)  -- OpenAI ada-002 dimensions
      );
    SQL

    create_table :leaf_embedding_metadata do |t|
      t.references :leaf, null: false, foreign_key: true
      t.integer :chunk_index, default: 0
      t.text :chunk_text
      t.timestamps
    end
  end
end
```

```ruby
# app/models/concerns/leaf/embeddable.rb
module Leaf::Embeddable
  extend ActiveSupport::Concern

  included do
    after_save_commit :generate_embedding_async, if: :searchable?
  end

  def generate_embedding
    return unless searchable_content.present?

    chunks = chunk_content(searchable_content)
    chunks.each_with_index do |chunk, index|
      embedding = EmbeddingService.generate(chunk)
      store_embedding(embedding, chunk, index)
    end
  end

  def similar_leaves(limit: 5)
    # Query sqlite-vss for similar content
    Leaf.find_by_sql([
      "SELECT leaves.*, vss_distance_l2(?, embedding) as distance
       FROM leaf_embeddings
       JOIN leaf_embedding_metadata ON leaf_embeddings.rowid = leaf_embedding_metadata.id
       JOIN leaves ON leaf_embedding_metadata.leaf_id = leaves.id
       WHERE leaves.book_id = ? AND leaves.id != ?
       ORDER BY distance
       LIMIT ?",
      primary_embedding, book_id, id, limit
    ])
  end

  private

  def chunk_content(text, max_tokens: 500)
    # Simple chunking - could use tiktoken for accurate token counts
    text.scan(/.{1,2000}/m)
  end
end
```

```ruby
# app/services/embedding_service.rb
class EmbeddingService
  def self.generate(text)
    client = OpenAI::Client.new
    response = client.embeddings(
      parameters: {
        model: "text-embedding-ada-002",
        input: text
      }
    )
    response.dig("data", 0, "embedding")
  end
end
```

### Option B: Enhanced FTS5 Search (Simpler, Good Enough)

**Approach:** Leverage the existing FTS5 setup with query expansion and ranking.

**Pros:**
- No additional infrastructure
- Already have FTS5 in place
- Fast and efficient
- Zero additional cost

**Cons:**
- Keyword-based (no semantic understanding)
- May miss conceptually related content
- Requires good keyword extraction

**Implementation:**

```ruby
# app/models/concerns/leaf/contextable.rb
module Leaf::Contextable
  extend ActiveSupport::Concern

  # Find related content from the same book
  def related_leaves(limit: 5)
    return [] unless searchable_content.present?

    # Extract key terms from current content
    key_terms = extract_key_terms(searchable_content)
    return [] if key_terms.empty?

    # Search within same book
    book.leaves
        .active
        .where.not(id: id)
        .search(key_terms.join(" OR "))
        .favoring_title
        .limit(limit)
  end

  private

  def extract_key_terms(text, max_terms: 10)
    # Simple TF-IDF-like extraction
    words = text.downcase.scan(/\w+/)

    # Remove stop words
    stop_words = %w[the a an is are was were be been being have has had do does did will would could should may might must shall can]
    words = words - stop_words

    # Get most frequent meaningful words
    words.tally
         .sort_by { |_, count| -count }
         .first(max_terms)
         .map(&:first)
  end
end
```

### Option C: Hybrid Search (Recommended)

**Approach:** Combine FTS5 for keyword search with embeddings for semantic search.

```ruby
# app/services/context_retrieval_service.rb
class ContextRetrievalService
  def initialize(leaf, query: nil)
    @leaf = leaf
    @query = query || leaf.searchable_content
    @book = leaf.book
  end

  def retrieve(limit: 5)
    # Get results from both methods
    fts_results = keyword_search(limit)
    semantic_results = semantic_search(limit)

    # Merge and deduplicate, prioritizing semantic matches
    combined = (semantic_results + fts_results).uniq(&:id)
    combined.first(limit)
  end

  private

  def keyword_search(limit)
    key_terms = extract_key_terms(@query)
    return [] if key_terms.empty?

    @book.leaves.active
         .where.not(id: @leaf.id)
         .search(key_terms.join(" OR "))
         .limit(limit)
  end

  def semantic_search(limit)
    return [] unless embeddings_enabled?

    @leaf.similar_leaves(limit: limit)
  end

  def embeddings_enabled?
    # Feature flag or config check
    Rails.application.config.x.embeddings_enabled
  end
end
```

---

## Part 3: Integration with Writing Assistant

### Enhanced Agent Context

Modify the `WritingAssistantAgent` to automatically include relevant context:

```ruby
# app/agents/writing_assistant_agent.rb
class WritingAssistantAgent < ApplicationAgent
  # ... existing code ...

  private

  def setup_content_params
    @content = params[:content]
    @selection = params[:selection]
    @full_content = params[:full_content]
    @context = params[:context]
    @has_selection = @selection.present?

    # NEW: Fetch related content from the book
    @related_content = fetch_related_content if params[:contextable]
  end

  def fetch_related_content
    return nil unless params[:contextable].respond_to?(:leaf)

    leaf = params[:contextable].leaf
    related = ContextRetrievalService.new(leaf, query: @selection || @content)
                                      .retrieve(limit: 3)

    return nil if related.empty?

    related.map do |related_leaf|
      {
        title: related_leaf.title,
        content: related_leaf.searchable_content&.truncate(500)
      }
    end
  end
end
```

### Updated Prompt Template

```erb
<%# app/views/writing_assistant_agent/improve.text.erb %>
Please <%= @task %><%= @has_selection ? " of the selected text" : " of the following content" %>:

<% if @context.present? %>
Context: <%= @context %>
<% end %>

<% if @related_content.present? %>
## Related content from this book (for reference):
<% @related_content.each do |related| %>
### <%= related[:title] %>
<%= related[:content] %>

<% end %>
<% end %>

<% if @has_selection %>
## Selected text to improve:
<%= @selection %>

<% if @full_content.present? && @full_content != @selection %>
## Full document context (for reference only):
<%= @full_content %>
<% end %>
<% else %>
## Content to improve:
<%= @content %>
<% end %>

Provide only the improved version of the content without any explanation.
```

---

## Part 4: Document Leafable for PDF/PPT Storage

### Complete Implementation

```ruby
# app/models/document.rb
class Document < ApplicationRecord
  include Leafable

  SUPPORTED_TYPES = %w[pdf pptx ppt docx].freeze

  has_one_attached :file do |attachable|
    attachable.variant :preview, resize_to_limit: [800, 800]
  end

  store :page_text, coder: JSON
  store :page_images, coder: JSON  # URLs to generated page images

  validates :document_type, inclusion: { in: SUPPORTED_TYPES }

  after_create_commit :process_document_async

  def searchable_content
    page_text.values.join("\n")
  end

  def text_for_pages(range)
    range.map { |n| page_text[n.to_s] }.compact.join("\n\n---\n\n")
  end

  def image_for_page(page_number)
    page_images[page_number.to_s]
  end

  # For LLM context - returns text or image URL depending on content quality
  def context_for_pages(range)
    range.map do |n|
      text = page_text[n.to_s]

      # If text extraction was poor (likely scanned), use image
      if text.blank? || text.length < 50
        { type: :image, url: image_for_page(n), page: n }
      else
        { type: :text, content: text, page: n }
      end
    end
  end

  private

  def process_document_async
    DocumentProcessingJob.perform_later(self)
  end
end
```

```ruby
# app/jobs/document_processing_job.rb
class DocumentProcessingJob < ApplicationJob
  queue_as :default

  def perform(document)
    case document.document_type
    when 'pdf'
      process_pdf(document)
    when 'pptx', 'ppt'
      process_pptx(document)
    when 'docx'
      process_docx(document)
    end
  end

  private

  def process_pdf(document)
    document.file.open do |file|
      # Extract text
      extractor = PdfTextExtractor.new(file.path)
      result = extractor.extract

      document.update!(
        page_count: result[:page_count],
        page_text: result[:pages]
      )

      # Generate page images for vision analysis
      generate_page_images(document, file.path)
    end
  end

  def generate_page_images(document, file_path)
    # Using ImageMagick/GraphicsMagick with Ghostscript
    images = {}

    (1..document.page_count).each do |page|
      output_path = Rails.root.join("tmp", "#{document.id}_page_#{page}.png")

      # Convert PDF page to PNG
      system("convert -density 150 '#{file_path}[#{page - 1}]' -quality 90 '#{output_path}'")

      if File.exist?(output_path)
        # Upload to Active Storage
        blob = ActiveStorage::Blob.create_and_upload!(
          io: File.open(output_path),
          filename: "page_#{page}.png",
          content_type: 'image/png'
        )
        images[page.to_s] = blob.signed_id

        FileUtils.rm(output_path)
      end
    end

    document.update!(page_images: images)
  end
end
```

---

## Part 5: Implementation Roadmap

### Phase 1: PDF Support (Core)
1. Add `Document` model and migration
2. Update `Leafable::TYPES` to include `Document`
3. Implement `PdfTextExtractor` service
4. Create `DocumentProcessingJob`
5. Add PDF upload UI in book editor
6. Integrate PDF.js for viewing

### Phase 2: Enhanced Context Retrieval
1. Add `Leaf::Contextable` concern
2. Implement `ContextRetrievalService` using FTS5
3. Update `WritingAssistantAgent` to include related content
4. Update prompt templates

### Phase 3: Vector Embeddings (Optional)
1. Add `sqlite-vss` or alternative vector store
2. Implement `EmbeddingService`
3. Add `Leaf::Embeddable` concern
4. Background job for embedding generation
5. Hybrid search implementation

### Phase 4: PPT/DOCX Support
1. Add LibreOffice headless for conversion
2. Implement PPTX text extraction
3. Implement DOCX text extraction
4. Unified document processing pipeline

### Phase 5: Document-Aware AI Assistant
1. Create `DocumentAnalyzerAgent` for multi-page analysis
2. Add page-range selection for context
3. Implement OCR fallback for scanned documents
4. Add document summarization capabilities

---

## Technical Requirements

### Dependencies
```ruby
# Gemfile additions
gem 'pdf-reader'        # Already present
gem 'mini_magick'       # For PDF to image conversion
gem 'sqlite-vss'        # Optional: vector search
gem 'tiktoken_ruby'     # Optional: accurate token counting
```

### System Dependencies
```bash
# For PDF processing
brew install poppler    # or apt-get install poppler-utils
brew install ghostscript
brew install imagemagick

# For PPT/DOCX conversion (optional)
brew install libreoffice  # Headless mode
```

### Configuration
```yaml
# config/application.rb
config.x.embeddings_enabled = ENV.fetch('EMBEDDINGS_ENABLED', false)
config.x.embedding_model = ENV.fetch('EMBEDDING_MODEL', 'text-embedding-ada-002')
```

---

## Cost Considerations

| Feature | Cost Driver | Estimate |
|---------|-------------|----------|
| PDF Text Extraction | CPU only | Free |
| PDF to Image Conversion | CPU + Storage | ~$0.001/page (storage) |
| Image Vision Analysis | GPT-4o tokens | ~$0.01-0.03/page |
| Text Embeddings | OpenAI API | ~$0.0001/1K tokens |
| Vector Search | CPU only | Free (sqlite-vss) |

---

## Summary Recommendations

1. **Start with Option B** (store & render PDFs) for document support
2. **Use Enhanced FTS5** (Option B for search) initially - it's already implemented
3. **Add embeddings later** if semantic search proves necessary
4. **Hybrid approach** for context retrieval provides best flexibility

The existing FTS5 infrastructure is solid and can be enhanced significantly before needing vector embeddings. Focus on good keyword extraction and query expansion first.
