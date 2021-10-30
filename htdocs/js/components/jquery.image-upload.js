(function($) {

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
