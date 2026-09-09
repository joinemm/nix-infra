{
  programs.swayimg = {
    enable = true;
    initLua = ''
      swayimg.overlay = false
      swayimg.imagelist.order = "mtime"
      swayimg.imagelist.reverse = true
      swayimg.imagelist.adjacent = true
      swayimg.text.timeout = 1

      swayimg.viewer.set_window_background(0xff000000)

      swayimg.viewer.on_mouse("ScrollUp", function()
        swayimg.viewer.scale = swayimg.viewer.scale + 0.05
      end)
      swayimg.viewer.on_mouse("ScrollDown", function()
        swayimg.viewer.scale = swayimg.viewer.scale - 0.05
      end)
      swayimg.viewer.on_key({ "j", "left" }, function()
        swayimg.viewer.open("prev")
      end)
      swayimg.viewer.on_key({ "k", "right" }, function()
        swayimg.viewer.open("next")
      end)
      swayimg.viewer.on_key("b", function()
        local image = swayimg.viewer.get_image()
        if image then
          os.execute("setbg " .. string.format("%q", image.path))
        end
      end)

      swayimg.gallery.on_mouse("ScrollUp", function()
        swayimg.gallery.thumb_size = swayimg.gallery.thumb_size + 20
      end)
      swayimg.gallery.on_mouse("ScrollDown", function()
        swayimg.gallery.thumb_size = swayimg.gallery.thumb_size - 20
      end)
      swayimg.gallery.on_key("j", function()
        swayimg.gallery.select("pgdown")
      end)
      swayimg.gallery.on_key("k", function()
        swayimg.gallery.select("pgup")
      end)
    '';
  };
}
