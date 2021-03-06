module Sass::Script::Functions

  def sprite_url(file)
    dir, name, basename = extract_names(file)
    sprite = sprite_for("#{dir}#{name}")
    Sass::Script::SpriteInfo.new(:url, sprite)
  end

  def sprite_position(file, options_string = '')
		options = options_string.blank? ? {} : eval(options_string.value)
    sprite, sprite_item = sprite_url_and_position(file, options)
    Sass::Script::SpriteInfo.new(:position, sprite, sprite_item, options)
  end

	def sprite_width(file)
		sprite, sprite_item = sprite_url_and_position(file)
		Sass::Script::SpriteInfo.new(:width, sprite, sprite_item)
	end

	def sprite_height(file)
		sprite, sprite_item = sprite_url_and_position(file)
		Sass::Script::SpriteInfo.new(:height, sprite, sprite_item)
	end

  def sprite_image(file, options_string = '')
		options = options_string.blank? ? {} : eval(options_string.value)
    sprite, sprite_item = sprite_url_and_position(file, options)
    Sass::Script::SpriteInfo.new(:both, sprite, sprite_item, options)
  end
  alias_method :sprite_img, :sprite_image

  def sprite_files_in_folder(folder)
    assert_type folder, :String
    count = sprite_file_list_from_folder(folder).length
    Sass::Script::Number.new(count)
  end

  def sprite_file_from_folder(folder, n)
    assert_type folder, :String
    assert_type n, :Number
    file = sprite_file_list_from_folder(folder)[n.to_i]
    file = File.basename(file)
    Sass::Script::String.new(File.join(folder.value, file))
  end

  def sprite_name(file)
    dir, name, basename = extract_names(file)
    Sass::Script::String.new(name)
  end

  def image_basename(file)
    dir, name, basename = extract_names(file, :check_file => true)
    Sass::Script::String.new(basename)
  end

private

  def sprite_file_list_from_folder(folder)
    dir = File.join(Lemonade.sprites_path, folder.value)
    Dir.glob(File.join(dir, '*.png')).sort
  end

  def sprite_url_and_position(file, options = {})
    dir, name, basename = extract_names(file, :check_file => true)
    filestr = File.join(Lemonade.sprites_path, file.value)

    sprite_file = "#{dir}#{name}.png"
    sprite = sprite_for(sprite_file)
    sprite_item = image_for(sprite, filestr, options)

    # Create a temporary destination file so compass doesn't complain about a missing image
    FileUtils.touch File.join(Lemonade.images_path, sprite_file)

    [sprite, sprite_item]
  end

  def extract_names(file, options = {})
    assert_type file, :String
    unless (file.value =~ %r(^(.+/)?([^\.]+?)(/(.+?)\.(png))?$)) == 0
      raise Sass::SyntaxError, 'Please provide a file in a folder: e.g. sprites/button.png'
    end
    dir, name, basename = $1, $2, $4
    if options[:check_file] and basename.nil?
      raise Sass::SyntaxError, 'Please provide a file in a folder: e.g. sprites/button.png'
    end
    [dir, name, basename]
  end

  def sprite_for(file)
    file = "#{file}.png" unless file =~ /\.png$/
    Lemonade.sprites[file] ||= {
        :file => "#{file}",
        :height => 0,
        :width => 0,
        :images => [],
        :margin_bottom => 0
      }
  end

  def image_for(sprite, file, options = {})
    image = sprite[:images].detect{ |image| image[:file] == file }
    margin_top_or_both ||= options[:margin_top_or_both] || Sass::Script::Number.new(0)
    margin_top = margin_top_or_both.value #calculate_margin_top(sprite, margin_top_or_both, margin_bottom)
    margin_bottom = (options[:margin_bottom] || margin_top_or_both).value
    if image
      image[:margin_top] = margin_top if margin_top > image[:margin_top]
      image[:margin_bottom] = margin_bottom if margin_bottom > image[:margin_bottom]
    else
      chunky_image = ChunkyPNG::Image.from_file(file)      
      width, height = chunky_image.width, chunky_image.height
      x = (options[:position_x] and options[:position_x].numerator_units == %w(%)) ? options[:position_x] : Sass::Script::Number.new(0)
      y = sprite[:height] + margin_top
      y = Sass::Script::Number.new(y, y == 0 ? [] : ['px'])
      image = {
        :file => file,
        :height => height,
        :width => width,
        :x => x,
        :margin_top => margin_top,
        :margin_bottom => margin_bottom,
        :index => sprite[:images].length,
        :repeat => options[:repeat],
      }
      sprite[:images] << image
    end
    image
  rescue Errno::ENOENT
    raise Sass::SyntaxError, "#{file} does not exist in sprites_dir #{Lemonade.sprites_path}"
  rescue ChunkyPNG::SignatureMismatch
    raise Sass::SyntaxError, "#{file} is not a recognized png file, can't use for sprite creation"
  end

end
