module.exports = function(grunt) {

  grunt.initConfig({
      npmcopy: {
          options: {
            // General options...
          },
          scripts: {
              options: {
                  destPrefix: 'src/main/webapp/assets/lib/js'
              },
              files: {
            	  'jquery.min.js':'jquery/dist/jquery.min.js',
            	  'bootstrap.min.js':'bootstrap/dist/js/bootstrap.min.js',
            	  'sweetalert2.min.js':'sweetalert2/dist/sweetalert2.min.js',
            	  'bootstrap-dialog.min.js': 'bootstrap3-dialog/dist/js/bootstrap-dialog.min.js',
            	  'jquery.fileDownload.js': 'jquery-file-download/src/Scripts/jquery.fileDownload.js',
            	  'jquery.ui.widget.js':'blueimp-file-upload/js/vendor/jquery.ui.widget.js',
            	  'jquery.iframe-transport.js':'blueimp-file-upload/js/jquery.iframe-transport.js',
            	  'jquery.fileupload.js':'blueimp-file-upload/js/jquery.fileupload.js',
            	  'select2.min.js':'select2/dist/js/select2.min.js'
              }
          },
          styles: {
              options: {
                  destPrefix: 'src/main/webapp/assets/lib/css'
              },
              files: {
                  'bootstrap.min.css': 'bootstrap/dist/css/bootstrap.min.css',
                  'jquery.fileupload.css': 'blueimp-file-upload/css/jquery.fileupload.css',
                  'sweetalert2.min.css': 'sweetalert2/dist/sweetalert2.min.css' ,
                  'bootstrap-dialog.min.css': 'bootstrap3-dialog/dist/css/bootstrap-dialog.min.css',
                  'font-awesome.min.css':'font-awesome/css/font-awesome.min.css',
                  //'jquery.fileupload-ui.css': 'blueimp-file-upload/css/jquery.fileupload-ui.css',
                  'select2.min.css':'select2/dist/css/select2.min.css',
                  'select2-bootstrap.min.css':'select2-bootstrap-theme/dist/select2-bootstrap.min.css'
              }
        	  
          },
          bootstrap_fonts: {
              files: {
                  'src/main/webapp/assets/lib/fonts': 'bootstrap/dist/fonts/*'
              }        	  
          },
          fontawesome_fonts: {
        	  files: {
                  'src/main/webapp/assets/lib/fonts': 'font-awesome/fonts/*'
              }
          }
      }
  });

  grunt.loadNpmTasks('grunt-npmcopy');
};
