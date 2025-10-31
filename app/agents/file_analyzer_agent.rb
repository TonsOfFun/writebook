require 'base64'

class FileAnalyzerAgent < ApplicationAgent
  generate_with :openai,
    model: "gpt-4o",
    instructions: "You are an expert document analyzer capable of extracting insights from PDFs, images, and other file types."

  def analyze_pdf
    # Read PDF content (would need pdf-reader gem)
    @content = extract_pdf_content(@file_path) if @file_path

    prompt
  end

  def analyze_image
    # For image analysis, OpenAI's vision models can be used
    @file_path = params[:file_path]
    @description_detail = params[:description_detail] || "medium"

    # For vision API, we need to encode the image properly
    if @file_path && File.exist?(@file_path)
      # Encode image as data URI for Active Agent
      image_data = "data:image/jpeg;base64,#{Base64.strict_encode64(File.read(@file_path))}"

      # Pass the image to the prompt using the image_data parameter
      prompt(
        content_type: :text,
        image_data: image_data
      )
    else
      prompt(content_type: :text)
    end
  end

  def extract_text
    @content = extract_file_content(@file_path) if @file_path

    prompt
  end

  def summarize_document
    @content = extract_file_content(@file_path) if @file_path

    prompt
  end

  private

  def extract_pdf_content(file_path)
    # This would require pdf-reader gem
    # For now, returning placeholder
    "PDF content extraction would go here"
  end

  def encode_image(file_path)
    # Base64 encode image for vision API
    Base64.strict_encode64(File.read(file_path))
  rescue
    nil
  end

  def extract_file_content(file_path)
    File.read(file_path)
  rescue
    "Unable to read file content"
  end
end
