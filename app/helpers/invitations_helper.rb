module InvitationsHelper
  def button_to_copy_to_clipboard(url, &)
    tag.button class: "btn", data: {
      controller: "copy-to-clipboard", action: "copy-to-clipboard#copy",
      copy_to_clipboard_success_class: "btn--success", copy_to_clipboard_content_value: url
    }, &
  end

  def web_share_button(url, title, text, &)
    tag.button class: "btn", hidden: true, data: {
      controller: "web-share", action: "web-share#share",
      web_share_url_value: url,
      web_share_text_value: text,
      web_share_title_value: title
    }, &
  end

  def qr_code_image(url)
    qr_code_link = QrCodeLink.new(url)
    image_tag qr_code_path(qr_code_link.signed), class: "qr-code center", alt: "QR Code"
  end
end
