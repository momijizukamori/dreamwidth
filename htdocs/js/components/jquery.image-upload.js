(function($) {

    // this variable is just so we can map the label to its input
    // it is not the same as the file id
    var _uiCounter = 0;
    var imageMap = {};
    var _uploadInProgress = false;
    var _metadataInProgress = false;
    var msg_log = $("#upload-log");
    
    function updateImageMap(id, attrs) {
        if (imageMap[id]) {
            imageMap[id] = {...imageMap[id], ...attrs};
        } else {
            imageMap[id] = attrs;
        }
    }

    function encodeHTML(html) {
        return html.replace( /([<>&"'\s])/g, function( m, c ) { return String.encodeEntity( c ) } );
    }

    function imageMaptoString() {
        var items = [];
        Object.keys(imageMap).forEach(function(key) {
        let image = imageMap[key];
        var escape_titletext = image.title ? encodeHTML(image.title) : null;
        var escape_alttext = image.alttext ? encodeHTML(image.alttext) : null;
        var thumbnail_url = image.url.replace(/(file\/)/g, `file/${image.size}x${image.size}/`);

        var text = [];
        text.push( `<a href='${image.url}'><img src='${thumbnail_url}'` );
        if ( escape_titletext ) text.push( ` title='${escape_titletext}'` );
        if ( escape_alttext ) text.push(` alt='${escape_alttext}'`);
        text.push( " /></a>" );
        items.push(text.join(""));
    });
    return items.join("\n");
    }
    // hide the upload button, we'll have another one for saving descriptions
    $(".upload-form input[type=submit], .upload-form .log").hide();

    var _doEditRequest = function( form_fields ) {
        // form fields are the actual input fields
        // we need to extract them into the form of:
        // {
        //     mediaid: { propname => value, propname => value },
        //     mediaid: { propname => vaule, propname => value }
        // }

        var data = {};
        $.each( form_fields, function( i, form_field ) {
            var file_id = form_field.getAttribute("data-file-id");

            if ( ! data[file_id] )
                data[file_id] = {};

            data[file_id][form_field.name] = form_field.value;

            if (form_field.name == "security" && form_field.value == "usemask")
                data[file_id]["allowmask"] = 1;

        });

        $.ajax( Site.siteroot + '/api/v1/file/edit', {
            'type'      : 'POST',
            'dataType'  : 'json',
            'contentType': 'application/json',

            'data'      : JSON.stringify( data )
        } )
        .done(function(data) {
            if ( ! _metadataInProgress ) {
                $(".upload-form .log")
                    .addClass( "success" )
                    .removeClass( "alert" )
                    .text( "Your descriptions have been saved." )
                    .fadeIn().delay(3000).fadeOut();
                $(".upload-form input[type=submit]").val(function() {
                    return $(this).data("original-text");
                });
            }

            $.each(data.result, updateImageMap);
        })
        .fail(function(jqXHR) {
            var response = JSON.parse(jqXHR.responseText);
            $(".upload-form .log")
                .addClass( "alert" )
                .removeClass( "success" )
                .text( "Unable to save: " + response.error )
                .fadeIn();
            $(".upload-form input[type=submit]").val(function() {
                    return $(this).data("original-text");
            });
        })
    };

    $(".upload-form-file-inputs")
        .find('.row')
            .prepend('<div class="large-12 columns"><div class="drop_zone">or drop images here</div></div>')
        .end();

    $(".upload-form-file-inputs")
    .find('input[type=file]')
        .attr( 'multiple', 'multiple' )
    .end()
    .fileupload({
        dataType: 'json',
        url: Site.siteroot + '/api/v1/file/new',

        autoUpload: false,

        previewMaxWidth: 300,
        previewMaxHeight: 800
    })
    .on( 'fileuploadadd', function(e, data) {
        var $output = $(".upload-form-preview ul");
        for ( var i = 0, f; f = data.files[i]; i++ ) {
            if ( f.type && f.type.indexOf( 'image') !== 0 ) {
                msg_log.addClass('error').removeClass('hidden').text("Invalid file type");
                return;
            }
            // show the file preview and let the user upload metadata
            data.context = $($('#template-file-metadata').html())
                .prependTo( $output );

            data.context
                .find("label").attr( "for", function() {
                    return $(this).data("for-name") + _uiCounter;
                }).end()
                .find(":input").attr( "id", function() {
                    return this.name + _uiCounter;
                });

            _uiCounter++;

            data.formData = {};
            data.submit();
        }

        // and then add a button to save metadata
        $(".upload-form input[type=submit]")
            .val( "Save Descriptions" ).show()
            .click(function() {
                var $this = $(this);
                if ( ! $this.data("original-text" ) ) {
                    $this.data( "original-text", $this.val())
                }
                $this.val( "Saving..." );
            });
    })
    .on( 'fileuploaddone', function( e, data ) {
        var response = data.result;

        if ( response.success ) {
            var file_id = response.result.id;

            updateImageMap(file_id, {url: response.result.url, size: 100 });

            data.context
                .attr( "id", "file_" + file_id )
                // update the form field names to use this image id
                .find(":input").attr( "data-file-id", function(i, name){
                    return file_id;
                }).end()
                .find(".progress").toggleClass( "secondary success" ).end()
                .find(".success").attr("style", "").end();
        } else {
            $(data.context).trigger( "uploaderror", [ { error : data.error } ] );
        }
    })
    .on( 'fileuploadfail', function(e, data) {
        var responseText;
        if ( data.jqXHR && data.jqXHR.responseText ) {
            var response = JSON.parse(data.jqXHR.responseText);
            responseText = response.error;
        }
        if ( ! responseText ) {
            responseText = data.errorThrown;
        }

        $(data.context).trigger( "uploaderror", [ { error: responseText } ] );
    })
    .on( 'fileuploadprocessalways', function( e, data ) {
        var index = data.index;
        var $node = data.context;

        if ( ! $node ) return;

        $node.find( ".image-preview").prepend( data.files[index].preview );
    })
    .on( 'fileuploadprogress', function (e, data) {
       var progress = parseInt(data.loaded / data.total * 100, 10);
       data.context.find( ".meter" ).css( 'width', progress + '%' );
    })
    .on( 'fileuploadstart', function(data) {
        _uploadInProgress = true;
    })
    // now make sure we upload the metadata in case we tried to submit metadata
    // before we got an id back (from the file upload)
    .on( 'fileuploadstop', function(data) {
        if ( _metadataInProgress ) {
            // now submit all form fields...
            _doEditRequest( $('.upload-form :input') );
            _metadataInProgress = false;
        }

        _uploadInProgress = false;
    })

    $(document).on('change','.media-item', function(e) {
        let id = e.target.dataset.fileId;
        let name = e.target.getAttribute("name");
        let value = e.target.value;
        let data = {};
        data[name] = value;
        updateImageMap(id, data);

    });

    $('.image-upload-flex-wrapper .submit').on( "click", function(e) {
        e.preventDefault();
        e.stopPropagation();

        var formFields = $(':input[data-file-id]', this);
        if ( formFields.length < $("input[type=text], select", this).length ) {
            _metadataInProgress = true;
        }

        _doEditRequest( formFields );

        console.log(imageMaptoString());
        $(document).trigger("imagecodeupdate", [imageMap]);
    });

    // error handler when uploading an image
    $(".upload-form-preview ul").on( 'uploaderror', function(e, data) {

        msg_log.addClass('error').removeClass('hidden').text(data.error);
        $(e.target)
            // error message
            .find( ".progress .meter" )
                .replaceWith( "<small class='error' role='alert'>" + data.error + "</small>")
            .end()
            // dim text fields (don't actually disable though, may still want the text inside)
            .find( ":input" )
                .addClass( "disabled" )
                .attr( "aria-invalid", true );

    }).on("imagecodeupdate", function(e, data) {
        console.log("image code updated");
        var $field = $(e.target);

        var image = $field.data( "image-attributes" );
        if ( ! image ) image = {};
        $.extend( image, data );
        $field.data( "image-attributes", image );

        var escape_titletext = '';
        if ( image.title ) escape_titletext = image.title
            .replace( /&/g, '&amp;' ).replace( /</g, '&lt;' ).replace( /'/g, "&apos;" );

        var escape_alttext = '';
        if ( image.alttext ) escape_alttext = image.alttext
            .replace( /&/g, '&amp;' ).replace( /</g, '&lt;' ).replace( /'/g, "&apos;" );

        var text = [];
        text.push( "<a href='" + image.url + "'><img src='" + image.thumbnail_url + "'" );
        if ( escape_titletext ) text.push( " title='" + escape_titletext + "' " );
        if ( escape_alttext ) text.push(" alt='" + escape_alttext + "' ");
        text.push( " /></a>" );
        $field.val(text.join(""));
    });

    $(window).on('beforeunload', function(e) {
        if(_uploadInProgress || _metadataInProgress) {
            return "Your files haven't finished uploading yet.";
        }
    });

function ImageUpload($el, options) {
    var imageUpload = this;
    var modalSelector = "#" + options.modalId;
    var scrollPositionDogear;

    $.extend(imageUpload, {
        element: $el,
        modal: $(modalSelector),
        modalId: options.modalId
    });

    $(options.triggerSelector).attr("data-reveal-id", options.modalId);


    $(document)
        .on('open.fndtn.reveal', modalSelector, function(e) {
            // hackety hack -- being triggered on both 'open' and 'open.fndtn.reveal'; just want one
            if (e.namespace === "") return;

            // If the page scrolled sideways, don't put the modal way out in left field.
            imageUpload.modal.css('left', window.scrollX);
            // imageUpload.registerListeners();
        })
        // Save and restore the scroll position when opening and closing the
        // modal. This is crucial on mobile if you have dozens of icons, because
        // otherwise it'll ditch you miles out into the comment thread, as you
        // wonder where you left your reply form and whether you have enough
        // water to survive the walk back to the gas station.
        .on('opened.fndtn.reveal', modalSelector, function(e) {
            // hackety hack -- being triggered on both 'opened' and 'opened.fndtn.reveal'; just want one
            if (e.namespace === "") return;

            scrollPositionDogear = $(window).scrollTop();
            imageUpload.modal.removeAttr('tabindex'); // WHY does foundation.reveal set this.
            imageUpload.focusActive();
        })
        .on('closed.fndtn.reveal', modalSelector, function(e) {
            // hackety hack -- being triggered on both 'closed' and 'closed.fndtn.reveal'; just want one
            if (e.namespace === "") return;

            if ( Math.abs( $(window).scrollTop() - scrollPositionDogear ) > 500 ) {
                $(window).scrollTop(scrollPositionDogear);
            }

            // the browser blew away the user's tab-through position, so restore
            // it on whatever makes most sense to focus. Defaults to the icon
            // menu, since that's what they just indirectly set a value for, but
            // in comment forms we ask to focus the message body instead.
            var $focusTarget = $el;
            if ( options.focusAfterBrowse ) {
                var $altTarget = $( options.focusAfterBrowse ).first();
                if ( $altTarget.length === 1 ) {
                    $focusTarget = $altTarget;
                }
            }
            // Only force-reset the focus if we know it's still wrong! If the
            // user somehow managed to focus something else before this handler
            // fired, don't jerk them around.
            if ( document.activeElement.tagName === 'BODY' ) {
                $focusTarget.focus();
            }
        });
}

ImageUpload.prototype = {
    kwToIcon: {},
    selectedId: undefined,
    selectedKeyword: undefined,
    imageUploadItems: [],
    iconsList: undefined,
    isLoaded: false,
    listenersRegistered: false,
    deregisterListeners: function() {
        $(document).off('keydown.icon-browser');
    },
    registerListeners: function() {
        $(document).on('keydown.icon-browser', this.keyboardNav.bind(this));

        if ( this.listenersRegistered ) return;

        $(document)
            .on('closed.fndtn.reveal', '#' + this.modalId, this.deregisterListeners.bind(this));

        this.listenersRegistered = true;
    },
    focusActive: function() {
        if ( this.selectedId ) {
            $('#' + this.selectedId).find("button.icon-browser-icon-button").focus();
        } else {
            $('#js-icon-browser-search').focus();
        }
    },
    keyboardNav: function(e) {
        if ( $(e.target).is('#js-icon-browser-search') ) return;

        if ( e.key === '/' || (! e.key && e.keyCode === 191) ) {
            e.preventDefault();
            $("#js-icon-browser-search").focus();
        }
    },
    selectByClick: function(e) {
        e.stopPropagation();
        e.preventDefault();

        // Some browsers don't focus buttons or role=buttons on click, and we
        // want predictable behavior when people combine click + tab/enter.
        e.target.focus();

        // this may be on either the icon or the keyword
        var container = $(e.target).closest("li");
        var keyword = $(e.target).closest(".keyword");

        // set the active icon and keyword:
        this.doSelect(container, keyword.length > 0 ? keyword.text() : null);

        // confirm and close:
        this.updateOwner.call(this, e);
    },
    selectByDoubleClick: function(e) {
        this.selectByClick.call(this, e);
    },
    initializeKeyword: function() {
        var keyword = this.element.val();
        this.doSelect($("#" + this.kwToIcon[keyword]), keyword);
    },
    doSelect: function($container, keyword) {
        var imageUpload = this;

        $("#" + imageUpload.selectedId).find(".th, .keywords a").removeClass("active");

        if ( ! $container || $container.length === 0 ) {
            // more like DON'Tselect.
            imageUpload.selectedKeyword = undefined;
            imageUpload.selectedId = undefined;
            return;
        }

        // select keyword
        if ( keyword != null ) {
            // select by keyword
            imageUpload.selectedKeyword = keyword;
        } else {
            // select by picid (first keyword)
            imageUpload.selectedKeyword = $container.data("defaultkw");
        }

        imageUpload.selectedId = $container.attr("id");
        $container
            .show()
            .find(".th")
                .addClass("active");
        $container
            .find(".keyword[data-kw='" + imageUpload.selectedKeyword + "']")
                .closest("a").addClass("active");
    },
    close: function() {
        this.modal.foundation('reveal', 'close');
    },
};

$.fn.extend({
    imageUpload: function(options) {

        return $(this).each(function(){
            var defaults = {
                triggerSelector: "#image-upload",
                modalId: "js-image-upload",
                // focusAfterBrowse: "",
                // preferences: { metatext: true, smallicons: false, keywordorder: false }
            };

            new ImageUpload($(this), $.extend({}, defaults, options));
        });

    }
});

})(jQuery);
