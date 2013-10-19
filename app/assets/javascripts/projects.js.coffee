# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).ready ->
  $(".revert").on 'click', (e) ->
    Pixastic.revert(document.getElementById("baseimage"))
  $(".invert").on 'click', (e) ->
    Pixastic.process(document.getElementById("baseimage"), "invert")
  $(".desaturate").on 'click', (e) ->
    Pixastic.process(document.getElementById("baseimage"), "desaturate")
  $(".brightness").on 'click', (e) ->
    Pixastic.process(document.getElementById("baseimage"), "brightness", {brightness:50,contrast:0})
  $(".darkness").on 'click', (e) ->
    Pixastic.process(document.getElementById("baseimage"), "brightness", {brightness:-50,contrast:0})
  $(".contrast").on 'click', (e) ->
    Pixastic.process(document.getElementById("baseimage"), "brightness", {brightness:0,contrast:0.25})
  $(".laplace").on 'click', (e) ->
    Pixastic.process(document.getElementById("baseimage"), "laplace", {edgeStrength:0.9,invert:false,greyLevel:0})
  $(".sepia").on 'click', (e) ->
    Pixastic.process(document.getElementById("baseimage"), "sepia")
  $(".hue").on 'click', (e) ->
    Pixastic.process(document.getElementById("baseimage"), "hsl", {hue:32,saturation:0,lightness:0})
  $(".solarize").on 'click', (e) ->
    Pixastic.process(document.getElementById("baseimage"), "solarize")
  $(".transparent").on 'click', (e) ->
    Pixastic.process(document.getElementById("baseimage"), "transparent")
  $(".transparent2").on 'click', (e) ->
    Pixastic.process(document.getElementById("baseimage"), "transparent", {white: true})
  $(".slider").slider({orientation: "horizontal", value: 50})
  $("#baseimage").fadeTo(200, 0.5)
  $(".slider").on "slidechange", ( event, ui ) ->
    $("#baseimage").fadeTo(100, ui.value / 100)

  window.URL = window.URL || window.webkitURL
  navigator.getUserMedia  = navigator.getUserMedia || navigator.webkitGetUserMedia || navigator.mozGetUserMedia || navigator.msGetUserMedia
  video = $('#capture video')[0]
  canvas = $('#capture canvas.camera')[0]
  thumb_canvas = $('#capture canvas.camera')[0]
  thumb_canvas.width = 128
  thumb_canvas.height = 128
  canvas.width = 500
  canvas.height = 500
  ctx = canvas.getContext('2d')
  localMediaStream = null

  snapshot = ->
    if (localMediaStream)
      diffH = video.clientHeight - canvas.height
      diffW = video.clientWidth - canvas.width
      thumb_ctx = thumb_canvas.getContext('2d')
      thumb_ctx.drawImage(video, -diffW / 2, -diffH / 2, 128, 128)
      thumb_blob =  canvas.toDataURL('image/webp')
      ctx.drawImage(video, -diffW / 2, -diffH / 2, video.clientWidth, video.clientHeight)
      blob =  canvas.toDataURL('image/webp')
      $('img#captured-image').attr 'src', blob
      $('img#baseimage').attr 'src', blob

      uploadImageFromBlob blob, thumb_blob

      $('img#thumbimage').attr 'src', thumb_blob

      $('img#thumbimage').show()
      $('img#captured-image').show()
      $(video).hide()

  pic = true
  $("#snapshot-button").on "click", ->
    if pic
      snapshot()
    else
      $('img#captured-image').hide()
      $('img#thumbimage').hide()
      $(video).show()
    pic = !pic

  video.addEventListener('click', snapshot, false)
  sourceStream = (stream) ->
    video.src = window.URL.createObjectURL(stream)
    localMediaStream = stream

  onFailSoHard = -> {}
  navigator.getUserMedia video: true, sourceStream, onFailSoHard

  uploadImageFromBlob = (blob, thumb_blob) ->
     fd = new FormData()
     fd.append("image", blob)
     fd.append("thumb", thumb_blob)
     $.ajax
       url: window.location.pathname.replace('edit','add_image'),
       data: fd,
       type: 'POST',
       processData: false,
       contentType: false,
       success: (data) ->
         console.log("enviou imagem e recebeu ", data)
