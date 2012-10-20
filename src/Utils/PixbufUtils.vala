// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*
 * Copyright (c) 2012 Noise Developers
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; see the file COPYING.  If not,
 * write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Lucas Baudin <xapantu@gmail.com>
 *              Victor Eduardo <victoreduardm@gmail.com>
 */

namespace Noise.PixbufUtils {

    /**
     * @param pixbuf original image
     * @param stretch whether to strech the image inside the square or keep the original dimensions
     * @return original pixbuf + drop shadow
     **/
    public Gdk.Pixbuf? get_pixbuf_shadow (Gdk.Pixbuf pixbuf, int surface_size, bool stretch = true) {
        const int SHADOW_SIZE = 15;

        int S_WIDTH = (stretch)? surface_size: pixbuf.width;
        int S_HEIGHT = (stretch)? surface_size : pixbuf.height;

        var buffer_surface = new Granite.Drawing.BufferSurface (S_WIDTH, S_HEIGHT);

        // paint shadow
        buffer_surface.context.rectangle (0, 0, S_WIDTH, S_HEIGHT);

        if (stretch)
            Gdk.cairo_set_source_pixbuf (buffer_surface.context,
              Icons.DEFAULT_ALBUM_SHADOW_PIXBUF.scale_simple (S_WIDTH, S_HEIGHT, Gdk.InterpType.BILINEAR), 0, 0);
        else
            Gdk.cairo_set_source_pixbuf (buffer_surface.context, Icons.DEFAULT_ALBUM_SHADOW_PIXBUF, 0, 0);

        buffer_surface.context.paint();

        S_WIDTH -= 2 * SHADOW_SIZE;
        S_HEIGHT -= 2 * SHADOW_SIZE;

        // paint original pixbuf
        var source_pixbuf = pixbuf;
        if (pixbuf.width != S_WIDTH || pixbuf.height != S_HEIGHT)
            source_pixbuf = pixbuf.scale_simple (S_WIDTH, S_HEIGHT, Gdk.InterpType.BILINEAR);

        Gdk.cairo_set_source_pixbuf (buffer_surface.context, source_pixbuf,
                                    SHADOW_SIZE, SHADOW_SIZE - 2); // 2px vertical offset
        buffer_surface.context.paint();

        return buffer_surface.load_to_pixbuf();
    }

    /**
     * @param surface_size size of the new pixbuf. Set a value of 0 to use the pixbuf's default size.
     **/
    public Gdk.Pixbuf? render_pixbuf_shadow (Gdk.Pixbuf pixbuf,
                                             int surface_size = Icons.ALBUM_VIEW_IMAGE_SIZE,
                                             int shadow_size = 5, double alpha = 0.75)
    {
        int S_WIDTH = (surface_size > 0)? surface_size : pixbuf.width;
        int S_HEIGHT = (surface_size > 0)? surface_size : pixbuf.height;

        var buffer_surface = new Granite.Drawing.BufferSurface (S_WIDTH, S_HEIGHT);

        S_WIDTH -= 2 * shadow_size;
        S_HEIGHT -= 2 * shadow_size;

        buffer_surface.context.rectangle (shadow_size, shadow_size, S_WIDTH, S_HEIGHT);
        buffer_surface.context.set_source_rgba (0, 0, 0, alpha);
        buffer_surface.context.fill();

        buffer_surface.fast_blur (2, 3);

        Gdk.cairo_set_source_pixbuf (buffer_surface.context,
                                     pixbuf.scale_simple (S_WIDTH, S_HEIGHT, Gdk.InterpType.BILINEAR),
                                     shadow_size,
                                     shadow_size);

        buffer_surface.context.paint();

        return buffer_surface.load_to_pixbuf();
    }

    public async Gdk.Pixbuf? get_pixbuf_from_file_async (File file, Cancellable? c = null) throws Error {
        return yield get_pixbuf_from_file_at_scale_async (file, -1, -1, false, c);
    }

    public async Gdk.Pixbuf? get_pixbuf_from_file_at_scale_async (File file, int width, int height,
                                                            bool preserve_aspect_ratio,
                                                            Cancellable? c = null) throws Error
    {
        Gdk.Pixbuf? image = null;
        var filestream = yield file.read_async (Priority.DEFAULT, c);

        if (filestream != null);
            image = new Gdk.Pixbuf.from_stream_at_scale (filestream, width, height,
                                                         preserve_aspect_ratio, c);

        return image;
    }

    public async void save_pixbuf_async (Gdk.Pixbuf pixbuf, File dest_file, string image_format,
                                         Cancellable? cancellable = null) throws Error
    {
        var output_stream = yield dest_file.create_async (FileCreateFlags.NONE, Priority.DEFAULT,
                                                          cancellable);

        if (Utils.is_cancelled (cancellable))
            return;

        uint8[] buffer;
        pixbuf.save_to_buffer (out buffer, image_format);

        yield output_stream.write_async (buffer, Priority.DEFAULT, cancellable);
        output_stream.close (null); // we don't want this to be cancellable
    }
}
