var elixir = require('laravel-elixir');

elixir(function(mix) {
    mix.webpack('../../../source/javascripts/_app.js', 'source/javascripts/app.js');

    mix.copy('node_modules/jquery/dist/jquery.min.js', 'source/javascripts/vendor/jquery.min.js');
    mix.copy('node_modules/bootstrap-sass/assets/javascripts/bootstrap.min.js', 'source/javascripts/vendor/bootstrap.min.js');
    mix.copy('node_modules/font-awesome/fonts', 'source/fonts/vendor');
});

