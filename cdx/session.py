import pandas as pd
from bokeh.session import PlotServerSession, PlotList
from objects import CDX, Namespace
from bokeh.objects import (
    Plot, DataRange1d, LinearAxis, Rule,
    ColumnDataSource, GlyphRenderer, ObjectArrayDataSource,
    PanTool, ZoomTool, SelectionTool, BoxSelectionOverlay)
from bokeh.glyphs import Circle
from bokeh.pandasobjects import PandasPlotSource, IPythonRemoteData
import os

class CDXSession(PlotServerSession):
    def __init__(self, username=None, serverloc=None, userapikey="nokey",
                 arrayserver_port=10020):
        self.arrayserver_port = arrayserver_port
        super(CDXSession, self).__init__(username=username,
                                         serverloc=serverloc,
                                         userapikey=userapikey)
    def load_doc(self, docid):
        super(CDXSession, self).load_doc(docid)
        cdx = self.load_type('CDX')
        if len(cdx):
            cdx = cdx[0]
        else:
            cdx = CDX()
            self.add(cdx)
            self.store_obj(cdx)
        self.cdx = cdx
        self.plotcontext.children.append(cdx)
        self.plotcontext._dirty = True
        if not cdx.namespace:
            ns = Namespace(name=self.docname)
            self.add(ns)
            cdx.namespace = ns
            self.store_obj(ns)
            self.store_obj(cdx)
        cdx.namespace.name = self.docname
        cdx.namespace.port = self.arrayserver_port
        if not cdx.plotcontext:
            cdx.plotcontext = self.plotcontext
            self.store_obj(cdx)

        if not cdx.plotlist:
            cdx.plotlist = PlotList()
            self.add(cdx.plotlist)
            self.store_objs([cdx, cdx.plotlist])
        #load namespace
        self.cdx.namespace.load()
        self.cdx.namespace.populate(todisk=False)
            
    @property
    def source(self):
        return self.cdx.activetable.source
    
    def reset(self):
        self.cdx.activetable = None
        self.cdx.plotlist.children = []
        self.cdx.plotlist._dirty = True
        self.cdx.namespace.data = {}
        self.cdx.activeplot = None


        
        self.store_all()
        
    def _get_plotsource(self, varname):
        plot_source = [m for m in self._models.values() \
                       if isinstance(m, PandasPlotSource) and \
                       m.source.varname == varname]
        if len(plot_source) > 0:
            return plot_source[0]
        remote_source = [m for m in self._models.values() \
                       if isinstance(m, IPythonRemoteData) and \
                       m.varname == varname]
        if len(remote_source) > 0:
            remote_source = remote_source[0]
        else:
            remote_source = IPythonRemoteData(host='localhost',
                                              port=self.arrayserver_port,
                                              varname=varname)
            self.add(remote_source)
        plot_source = PandasPlotSource(source=remote_source)
        self.add(plot_source)
        return plot_source
            
    def plot(self, xname, yname, varname, load=True):
        if load:
            self.load_all()
        plot_source = self._get_plotsource(varname)
        xdr = DataRange1d(sources=[plot_source.columns(xname)])
        ydr = DataRange1d(sources=[plot_source.columns(yname)])
        circle = Circle(x=xname, y=yname, fill="blue", alpha=0.6, radius=3,
                        line_color="black")
        nonselection_circle = Circle(x="weight", y="mpg", fill="blue",
                                     fill_alpha=0.1, radius=3,
                                     line_color="black")
        glyph_renderer = GlyphRenderer(
            data_source = plot_source,
            xdata_range = xdr,
            ydata_range = ydr,
            glyph = circle,
            nonselection_glyph = nonselection_circle,
            )
        pantool = PanTool(dataranges = [xdr, ydr],
                          dimensions=["width","height"])
        zoomtool = ZoomTool(dataranges=[xdr, ydr],
                            dimensions=("width","height"))
        selecttool = SelectionTool(renderers=[glyph_renderer])
        overlay = BoxSelectionOverlay(tool=selecttool)
        plot = Plot(x_range=xdr, y_range=ydr, data_sources=[],
                    border= 80)
        xaxis = LinearAxis(plot=plot, dimension=0)
        yaxis = LinearAxis(plot=plot, dimension=1)
        xgrid = Rule(plot=plot, dimension=0)
        ygrid = Rule(plot=plot, dimension=1)
        plot.renderers.append(glyph_renderer)
        plot.tools = [pantool, zoomtool, selecttool]
        plot.renderers.append(overlay)
        self.add(plot, glyph_renderer, xaxis, yaxis, xgrid, ygrid, plot_source, xdr, ydr, pantool, zoomtool, selecttool, overlay)
        self.cdx.plotlist.children.insert(0, plot)
        self.cdx.activeplot = plot
        self.cdx.plotlist._dirty = True
        stored = self.store_all()
        return stored
