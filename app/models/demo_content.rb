class DemoContent
  class << self
    def create_manual(user)
      book = create_book(user)
      load_markdown_pages(book)
    end

    private
      def create_book(user)
        Book.create(title: "The Writebook Manual", author: "37signals", everyone_access: true).tap do |book|
          with_attachment("writebook-manual.jpg") { |attachment| book.cover.attach(attachment) }
          book.update_access(readers: [], editors: [ user.id ])
        end
      end

      def load_markdown_pages(book)
        pages = {}

        Dir.glob(Rails.root.join("app/assets/markdown/demo/*.md")).each do |fname|
          front_matter = FrontMatterParser::Parser.parse_file(fname)

          if front_matter["class"] == "Section"
            load_section(book, front_matter)
          else
            page = load_markdown_page(book, front_matter)
            attach_images(page)
            pages[page.leaf.slug] = page
          end
        end

        book.leaves.pages.each { |leaf| localize_ref_links(leaf.page, pages) }
      end

      def load_markdown_page(book, front_matter)
        book.press(Page.new(body: front_matter.content), title: front_matter["title"]).page
      end

      def load_section(book, front_matter)
        book.press Section.new(body: front_matter.content, theme: front_matter["theme"]), title: front_matter["title"]
      end

      def attach_images(page)
        re = %r{
          \/u\/           # leading portion of path
          (\S+-\w+\.\w+)  # filename including slug and extension
        }x

        body = page.body.content.gsub(re) do |match|
          with_attachment($1) { |attachment| page.body.uploads.attach(attachment) }

          attachment = page.body.uploads.attachments.last
          attachment.analyze

          "/u/" + attachment.slug
        end

        page.update!(body: body)
      end

      def localize_ref_links(page, pages)
        re = %r{
          (\[.+\])              # link title
          \(                    # opening paren
          \/\d+\/[\w-]+\/\d+\/  # leading portion of path
          ([\w-]+)              # leaf slug
        }x

        body = page.body.content.gsub(re) do |match|
          link_title, leaf_slug, anchor = $1, $2, $3
          linked_page = pages[leaf_slug]
          raise "Invalid reference link: #{page_title}" unless linked_page.present?

          url = Rails.application.routes.url_helpers.leafable_slug_path(linked_page.leaf, anchor: anchor, only_path: true)

          "#{link_title}(#{url}"
        end

        page.update!(body: body)
      end

      def with_attachment(filename)
        File.open(Rails.root.join("app/assets/images/demo/#{filename}")) do |file|
          yield io: file, filename: filename
        end
      end
  end
end
