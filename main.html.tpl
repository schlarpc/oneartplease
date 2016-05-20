<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <title>One Art Please</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/meyer-reset/2.0/reset.min.css" />
    <style>
      html, body, .streams {
        height: 100%;
        overflow: hidden;
        background-color: black;
      }
      {% if not config['no_censor'] %}
      body {
        -webkit-filter: blur({{ config['blur'] }}px);
      }
      {% endif %}
      .stream {
        height: {{ 100 / config['height'] }}%;
        width: {{ 100 / config['width'] }}%;
        display: inline-block;
      }
      video {
        object-fit: cover;
      }
    </style>
  </head>
  <body>
    <div class="streams"></div>
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/2.1.3/jquery.min.js" type="text/javascript"></script>
    <script src="https://cdn.jsdelivr.net/clappr/latest/clappr.min.js" type="text/javascript"></script>

    <script>
      "use strict";

      $(function(){
        $.getJSON('/users', function(users) {
          users = users.slice(0, {{ config['width'] * config['height'] }});
          for (let i = 0; i < users.length; i++) {
            let user = users[i];
            $('.streams').append($('<div>').attr('class', 'stream').attr('id', 'stream-' + user['name']));
            new Clappr.Player({
              'source': user['stream'],
              'parentId': '#stream-' + user['name'],
              'mute': 'true',
              'chromeless': 'true',
              'autoPlay': 'true',
              'width': '100%',
              'height': '100%',
            });
          }
        });

        {% if not config['no_colors'] %}
        let tick = 0;
        (function tickHue(){
          $('.streams').css('-webkit-filter', 'hue-rotate(' + tick / 2 + 'deg)');
          tick = tick + 1 % 720;
          window.requestAnimationFrame(tickHue);
        })();
        {% endif %}

        {% if not config['no_censor'] %}
        $('body').click(function() {
          $(this).css('-webkit-filter', $(this).css('-webkit-filter') != 'none' ? 'unset' : 'blur(' + {{ config['blur'] }} + 'px)');
        });
        {% endif %}
      });
      /*
      let streamCount = 0;
      let currentStreams = [];

      function arrayDiff(a, b) {
        return a.filter(function(i) {return b.indexOf(i) < 0;});
      }

      function updateStreams() {
        $.getJSON('/streams', function (data) {
          let topStreams = data.slice(0, Math.min(data.length, streamCount));
          for (let streamName of topStreams) {
            if (currentStreams.indexOf(streamName) < 0) {
              let targetElement;

              if ($('.stream').length < streamCount) {
                targetElement = $('<div>').addClass('stream').attr('autoplay', '').attr('muted', '').appendTo('.streams');
              } else {
                for (let victim of arrayDiff(currentStreams, topStreams)) {
                  let victimElement = $('.stream').filter(function() { return $(this).data('streamer') === victim });
                  if (victimElement.length) {
                    console.log('Evicting', victim, 'for', streamName);
                    targetElement = victimElement;
                    break;
                  }
                }
              }
              targetElement.text(streamName).data('streamer', streamName).attr('src', '/streams/' + streamName);;
            }
          }
          currentStreams = topStreams;
        });
      }

      $(function () {
        streamCount = (document.documentElement.clientWidth / 320 | 0) * (document.documentElement.clientHeight / 240 | 0);
        updateStreams();
        setInterval(updateStreams, 20000);
      });*/
    </script>
  </body>
</html>