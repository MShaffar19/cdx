define [
  "underscore"
  "jquery_ui"
  "backbone"
  "common/has_parent"
  "common/has_properties"
  "common/continuum_view"
], (_, $, Backbone, HasParent, HasProperties, ContinuumView) ->

  class PivotView extends ContinuumView.View

    initialize: (options) ->
      super(options)
      @listenTo(@model, 'destroy', @remove)
      @listenTo(@model, 'change', @render)
      @render()

    render: () ->
      @$el.addClass("cdx-pivot-tool")
      ul = $('<ul></ul>')
      ul.append(@renderRows())
      ul.append(@renderColumns())
      ul.append(@renderValues())
      ul.append(@renderFilters())
      ul.append(@renderUpdate())
      @$el.html(ul)

    mpush: (attr, value) ->
      @mset(attr, @mget(attr).concat([value]))

    renderAdd: (exclude, handler) ->
      dropdown = $('<div class="dropdown pull-right"></div>')
      button = $('<button class="btn btn-link btn-xs dropdown-toggle"><i class="fa fa-plus"></i></button>')
      dropdown.append([button.dropdown(), @renderFields(exclude, handler)])
      dropdown

    renderFields: (exclude, handler) ->
      fields = _.difference(@mget("fields"), exclude)
      menu = $('<ul class="dropdown-menu"></ul>')
      items = _.map fields, (field) ->
        link = $('<a tabindex="-1" href="javascript://"></a>')
        link.text(field)
        item = $('<li></li>')
        item.append(link)
      menu.append(items)
      menu.click (event) -> handler($(event.target).text())

    renderRemove: (attr, field) ->
      handler = (event) => @mset(attr, _.reject(@mget(attr), (item) -> item.field == field))
      $('<span class="close pull-right">&times;</span>').click(handler)

    renderOptions: (options, value) ->
      menu = $('<ul class="dropdown-menu"></ul>')
      items = _.map options, (option) =>
        link = $('<a tabindex="-1" href="javascript://"></a>')
        link.text(option)
        item = $('<li></li>')
        item.append(link)
      menu.append(items)
      dropdown = $('<span class="dropdown"></span>')
      button = $('<button class="btn btn-link btn-xs dropdown-toggle"></button>')
      text = if typeof(value) == 'number' then options[value] else value
      button.text(text)
      button.append('&nbsp;')
      button.append($('<span class="caret"></span>'))
      dropdown.append([button.dropdown(), menu])

    defaultRowColumn: (field) ->
      {field: field, order: "ascending", sort_by: 'index', totals: true}

    usedFields: () ->
      _.map(@mget("rows").concat(@mget("columns")), (item) -> item.field)

    renderRows: () ->
      el = $("<li></li>")
      header = $("<div>Rows</div>")
      add = @renderAdd @usedFields(), (field) => @mpush("rows", @defaultRowColumn(field))
      header.append(add)
      rows = $('<ul></ul>')
      _.each @mget("rows"), (row) =>
        groupBy = $('<li class="cdx-pivot-header">Group by:&nbsp;</li>')
        remove = @renderRemove("rows", row.field)
        groupBy.append([row.field, remove])
        order = $('<li>Order:&nbsp;</li>')
        order.append(@renderOptions(["Ascending", "Descending"], 0))
        sortBy = $('<li>Sort by:&nbsp;</li>')
        totals = $('<li>Totals:&nbsp;</li>')
        totals.append(@renderOptions(["On", "Off"], 0))
        row = $('<ul class="cdx-pivot-box"></ul>')
        row.append([groupBy, order, sortBy, totals])
        rows.append(row)
      el.append([header, rows.sortable()])

    renderColumns: () ->
      el = $("<li></li>")
      header = $("<div>Columns</div>")
      add = @renderAdd @usedFields(), (field) => @mpush("columns", @defaultRowColumn(field))
      header.append(add)
      columns = $('<ul></ul>')
      _.each @mget("columns"), (column) =>
        groupBy = $('<li class="cdx-pivot-header">Group by:&nbsp;</li>')
        remove = @renderRemove("columns", column.field)
        groupBy.append([column.field, remove])
        order = $('<li>Order:&nbsp;</li>')
        order.append(@renderOptions(["Ascending", "Descending"], 0))
        sortBy = $('<li>Sort by:&nbsp;</li>')
        totals = $('<li>Totals:&nbsp;</li>')
        totals.append(@renderOptions(["On", "Off"], 0))
        column = $('<ul class="cdx-pivot-box"></ul>')
        column.append([groupBy, order, sortBy, totals])
        columns.append(column)
      el.append([header, columns.sortable()])

    defaultValue: (field) ->
      {field: field, aggregate: "count"}

    renderValues: () ->
      el = $("<li></li>")
      header = $("<div>Values</div>")
      add = @renderAdd [], (field) => @mpush("values", @defaultValue(field))
      header.append(add)
      values = $('<ul></ul>')
      _.each @mget("values"), (value) =>
        display = $('<li class="cdx-pivot-header">Display:&nbsp;</li>')
        remove = @renderRemove("values", value.field)
        display.append([value.field, remove])
        aggregate = $('<li>Aggregate:&nbsp;</li>')
        aggregate.append(@renderOptions(@model.aggregates, 0))
        value = $('<ul class="cdx-pivot-box"></ul>')
        value.append([display, aggregate])
        values.append(value)
      el.append([header, values.sortable()])

    defaultFilter: (field) ->
      {field: field}

    renderFilters: () ->
      el = $("<li></li>")
      header = $("<div>Filters</div>")
      add = @renderAdd [], (field) => @mpush("filters", @defaultFilter(field))
      header.append(add)
      filters = $('<ul></ul>')
      _.each @mget("filters"), (filter) =>
        header = $('<li class="cdx-pivot-header">Filter:&nbsp;</li>')
        remove = @renderRemove("filters", filter.field)
        header.append([value.field, remove])
        filter = $('<ul class="cdx-pivot-box"></ul>')
        filter.append([header])
        filters.append(filter)
      el.append([header, filters.sortable()])

    renderUpdate: () ->
      manual_update = @mget("manual_update")
      el = $("<li></li>")
      update = $('<div>Update:&nbsp;</div>')
      update.append(@renderOptions(["Manual", "Automatic"], if manual_update then 0 else 1))
      el.append(update)
      if manual_update
        button = $('<button type="button" class="btn btn-primary btn-lg">Update</button>')
        button.click (event) => @model.save()
        el.append(button)
      el

  class Pivot extends HasParent
    default_view: PivotView
    type: "Pivot"
    defaults:
      source: null
      fields: []
      rows: []
      columns: []
      values: []
      filters: []
      manual_update: true
    aggregates: ["count", "counta", "countunique", "average", "max", "min", "median", "sum", "product", "stdev", "stdevp", "var", "varp"]

  class Pivots extends Backbone.Collection
    model: Pivot

  class PivotTableView extends ContinuumView.View

    initialize: (options) ->
      super(options)
      @listenTo(@model, 'destroy', @remove)
      @listenTo(@model, 'change', @render)
      @render()

    render: () -> @pivotUI()

    renderers:
      "Table":          (pvtData) -> pivotTableRenderer(pvtData)
      #"Table Barchart": (pvtData) -> pivotTableRenderer(pvtData).barchart()
      #"Heatmap":        (pvtData) -> pivotTableRenderer(pvtData).heatmap()
      #"Row Heatmap":    (pvtData) -> pivotTableRenderer(pvtData).heatmap("rowheatmap")
      #"Col Heatmap":    (pvtData) -> pivotTableRenderer(pvtData).heatmap("colheatmap")

    spanSize: (arr, i, j) ->
      if i != 0
        noDraw = true
        for x in [0..j]
          if arr[i-1][x] != arr[i][x]
            noDraw = false
        if noDraw
          return -1 #do not draw cell
      len = 0
      while i+len < arr.length
        stop = false
        for x in [0..j]
          stop = true if arr[i][x] != arr[i+len][x]
        break if stop
        len++
      return len

    getAggregator: (rowKey, colKey) =>
      data = @mget("data")
      row = data.rows.indexOf(rowKey)
      col = data.cols.indexOf(colKey)
      row = data.rows.length-1 if row == -1
      col = data.cols.length-1 if col == -1
      value = data.values[row][col]
      return {value: (-> value), format: ((value) -> "" + value)}
      ###
      debugger
      flatRowKey = @flattenKey rowKey
      flatColKey = @flattenKey colKey
      if rowKey.length == 0 and colKey.length == 0
        agg = @allTotal
      else if rowKey.length == 0
        agg = @colTotals[flatColKey]
      else if colKey.length == 0
        agg = @rowTotals[flatRowKey]
      else
        agg = @tree[flatRowKey][flatColKey]
      return agg ? {value: (-> null), format: -> ""}
      ###

    pivotTableRenderer: () ->
      rowAttrs = @mget("rows")
      colAttrs = @mget("cols")
      rowKeys = @mget("data").rows
      colKeys = @mget("data").cols

      #now actually build the output
      result = $("<table class='pvtTable'>")

      #the first few rows are for col headers
      for own j, c of colAttrs
        tr = $("<tr>")
        if parseInt(j) == 0 and rowAttrs.length != 0
          tr.append $("<th>")
            .attr("colspan", rowAttrs.length)
            .attr("rowspan", colAttrs.length)
        tr.append $("<th class='pvtAxisLabel'>").text(c)
        for own i, colKey of colKeys
          x = @spanSize(colKeys, parseInt(i), parseInt(j))
          if x != -1
            th = $("<th class='pvtColLabel'>").text(colKey[j]).attr("colspan", x)
            if parseInt(j) == colAttrs.length-1 and rowAttrs.length != 0
              th.attr("rowspan", 2)
            tr.append th
        if parseInt(j) == 0
          tr.append $("<th class='pvtTotalLabel'>").text("Totals")
            .attr("rowspan", colAttrs.length + (if rowAttrs.length ==0 then 0 else 1))
        result.append tr

      #then a row for row header headers
      if rowAttrs.length !=0
        tr = $("<tr>")
        for own i, r of rowAttrs
          tr.append $("<th class='pvtAxisLabel'>").text(r)
        th = $("<th>")
        if colAttrs.length ==0
          th.addClass("pvtTotalLabel").text("Totals")
        tr.append th
        result.append tr

      #now the actual data rows, with their row headers and totals
      for own i, rowKey of rowKeys
        tr = $("<tr>")
        for own j, txt of rowKey
          x = @spanSize(rowKeys, parseInt(i), parseInt(j))
          if x != -1
            th = $("<th class='pvtRowLabel'>").text(txt).attr("rowspan", x)
            if parseInt(j) == rowAttrs.length-1 and colAttrs.length !=0
              th.attr("colspan",2)
            tr.append th
        for own j, colKey of colKeys
          aggregator = @getAggregator(rowKey, colKey)
          val = aggregator.value()
          tr.append $("<td class='pvtVal row#{i} col#{j}'>")
            .text(aggregator.format val)
            .data("value", val)

        totalAggregator = @getAggregator(rowKey, [])
        val = totalAggregator.value()
        tr.append $("<td class='pvtTotal rowTotal'>")
          .text(totalAggregator.format val)
          .data("value", val)
          .data("for", "row"+i)
        result.append tr

      #finally, the row for col totals, and a grand total
      tr = $("<tr>")
      th = $("<th class='pvtTotalLabel'>").text("Totals")
      th.attr("colspan", rowAttrs.length + (if colAttrs.length == 0 then 0 else 1))
      tr.append th
      for own j, colKey of colKeys
        totalAggregator = @getAggregator([], colKey)
        val = totalAggregator.value()
        tr.append $("<td class='pvtTotal colTotal'>")
          .text(totalAggregator.format val)
          .data("value", val)
          .data("for", "col"+j)
      totalAggregator = @getAggregator([], [])
      val = totalAggregator.value()
      tr.append $("<td class='pvtGrandTotal'>")
        .text(totalAggregator.format val)
        .data("value", val)
      result.append tr

      #squirrel this away for later
      result.data "dimensions", [rowKeys.length, colKeys.length]

      return result

    pivotUI: () ->
      opts = {
        data: @mget("data")
        rows: @mget("rows")
        cols: @mget("cols")
        vals: @mget("vals")
        renderer: @mget("renderer")
        renderers: @mget("renderers")
        aggregator: @mget("aggregator")
        aggregators: @mget("aggregators")
        hiddenAttributes: @mget("hiddenAttributes")
        derivedAttributes: @mget("derivedAttributes")
      }

      # figure out the cardinality and some stats
      ###
      axisValues = {}
      axisValues[x] = {} for x in opts.attrs

      forEachRecord opts.data, opts.derivedAttributes, (record) ->
        for own k, v of record
          v ?= "null"
          axisValues[k][v] ?= 0
          axisValues[k][v]++
      ###

      #start building the output
      uiTable = $("<table cellpadding='5'>")

      #renderer control
      rendererControl = $("<td>")

      renderer = $("<select id='renderer'>").bind("change", -> refresh())
      for own x of opts.renderers
        renderer.append $("<option>").val(x).text(x)
      rendererControl.append renderer

      # axis list, including the double-click menu

      colList = $("<td class='pvtAxisContainer pvtHorizList'>")
      attrs = opts.data.attrs
      for i, c of attrs
        do (c) ->
          #keys = (k for k of axisValues[c])
          colLabel = $("<nobr>").text(c)
          ###
          valueList = $("<div>")
            .css
              "z-index": 100
              "width": "280px"
              "height": "350px"
              "overflow": "scroll"
              "border": "1px solid gray"
              "background": "white"
              "display": "none"
              "position": "absolute"
              "padding": "20px"
          valueList.append $("<strong>").text "#{keys.length} values for #{c}"
          if keys.length > opts.menuLimit
            valueList.append $("<p>").text "(too many to list)"
          else
            btns = $("<p>")
            btns.append $("<button>").text("Select All").bind "click", ->
              valueList.find("input").attr "checked", true
            btns.append $("<button>").text("Select None").bind "click", ->
              valueList.find("input").attr "checked", false
            valueList.append btns
            for k in keys.sort()
               v = axisValues[c][k]
               filterItem = $("<label>")
               filterItem.append $("<input type='checkbox' class='pvtFilter'>")
                .attr("checked", true).data("filter", [c,k])
               filterItem.append $("<span>").text "#{k} (#{v})"
               valueList.append $("<p>").append(filterItem)
          colLabel.bind "dblclick", (e) ->
            valueList.css(left: e.pageX, top: e.pageY).toggle()
            valueList.bind "click", (e) -> e.stopPropagation()
            $(document).one "click", ->
              refresh()
              valueList.toggle()
          ###
          colList.append $("<li id='axis_#{i}'>").append(colLabel)#.append(valueList)

      uiTable.append $("<tr>").append(rendererControl).append(colList)

      tr1 = $("<tr>")

      #aggregator menu and value area

      aggregator = $("<select id='aggregator'>")
        .css("margin-bottom", "5px")
        .bind("change", -> refresh())
      for own x of opts.aggregators
        aggregator.append $("<option>").val(x).text(x)

      tr1.append $("<td id='vals' class='pvtAxisContainer pvtHorizList'>")
        .css("text-align", "center")
        .append(aggregator).append($("<br>"))

      #column axes
      tr1.append $("<td id='cols' class='pvtAxisContainer pvtHorizList'>")

      uiTable.append tr1

      tr2 = $("<tr>")

      #row axes
      tr2.append $("<td valign='top' id='rows' class='pvtAxisContainer'>")

      #the actual pivot table container
      pivotTable = $("<td valign='top'>")
      tr2.append pivotTable

      finalRender = =>
        html = @pivotTableRenderer()
        pivotTable.html(html)

      uiTable.append tr2

      #render the UI in its default state
      @$el.html uiTable

      #set up the UI initial state as requested by moving elements around
      for x in opts.cols
        @$el.find("#cols").append @$el.find("#axis_#{attrs.indexOf(x)}")
      for x in opts.rows
        @$el.find("#rows").append @$el.find("#axis_#{attrs.indexOf(x)}")
      for x in opts.vals
        @$el.find("#vals").append @$el.find("#axis_#{attrs.indexOf(x)}")
      if opts.aggregator?
        @$el.find("#aggregator").val opts.aggregator
      if opts.renderer?
        @$el.find("#renderer").val opts.renderer

      refresh = =>
        #subopts = {derivedAttributes: opts.derivedAttributes}
        #
        cols = []
        rows = []
        vals = []

        @$el.find("#rows li nobr").each -> rows.push $(this).text()
        @$el.find("#cols li nobr").each -> cols.push $(this).text()
        @$el.find("#vals li nobr").each -> vals.push $(this).text()
        #@$el.

        #subopts.aggregator = opts.aggregators[aggregator.val()](vals)
        #subopts.renderer = opts.renderers[renderer.val()]

        #exclusions = []
        #@$el.find('input.pvtFilter').not(':checked').each ->
        #  exclusions.push $(this).data("filter")

        #subopts.filter = (record) ->
        #  for [k,v] in exclusions
        #    return false if "#{record[k]}" == v
        #  return true

        result = @model.save({
          rows: rows
          cols: cols
          vals: vals
          #renderer: renderer
          #aggregator: aggregator
        }, {patch: true})

        result.done =>
          finalRender()

      finalRender()

      @$el.find(".pvtAxisContainer")
         .sortable({connectWith:".pvtAxisContainer", items: 'li'})
         .bind("sortstop", refresh)

  class PivotTable extends HasParent
    type: "PivotTable"
    default_view: PivotTableView

    defaults:
      #source: null
      #data: {}
      #rows: []
      #cols: []
      #vals: []
      renderer: "table"
      renderers: {"table": 1, "table-barchart": 1, "heatmap": 1, "row-heatmap": 1, "col-heatmap": 1}
      aggregator: "count"
      aggregators: {"count": 1, "sum": 1, "average": 1}
      hiddenAttributes: []
      derivedAttributes: []

  class PivotTables extends Backbone.Collection
    model: PivotTable

  return {
    Model: Pivot
    Collection: new Pivots()
    View: PivotView
  }
