$CDX.ws_conn_string = "ws://#{window.location.host}/cdx/sub"
$(()->
  $CDX.utility.load_default_document()
)
$.when($CDX.Promises.doc_loaded).then(()->
  $('#PlotPane').empty().append($CDX.plotcontextview.el)
)
