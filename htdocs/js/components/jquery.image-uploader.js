

$(document).ready(function() {

    var imageUploader = $("#image-upload");
    console.log("trying to init image uploader");

    if ( $.fn.imageUpload ) {
        console.log("we have image uploader");
        $('#js-icon-browser').removeClass('hide-image-upload');
        imageUploader.imageUpload({
            triggerSelector: "#image-upload",
            modalId: "js-image-upload",
            }
        );
    }
}); 