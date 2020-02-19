#
# URN registry for Monaco resources, only from a local installation
# for now. At the time of writing, CDN support runs into limitations
# in AMD mode for the cross-domain case (i.e., CDNs) and for web
# workers.
#
# There seems to be a cross-domain solution, but this requires more
# fiddling at the both ends, client and server (to-do):
#
# See https://github.com/microsoft/monaco-editor/blob/master/docs/integrate-amd-cross.md
#

set MONACO_CSS_PATHS {
  min/vs/editor/editor.main
  dev/vs/editor/editor.main
}

set MONACO_JS_PATHS {
  min/vs/loader
  min/vs/editor/editor.main.nls
  min/vs/editor/editor.main
  dev/vs/loader
  dev/vs/editor/editor.main.nls
  dev/vs/editor/editor.main
}

# local-only resources

template::register_urn \
    -urn      urn:ad:css:monaco:plugin \
    -resource /resources/xowf-monaco-plugin/plugin.css

template::register_urn \
    -urn      urn:ad:js:monaco:plugin \
    -resource /resources/xowf-monaco-plugin/plugin.js

foreach path $MONACO_CSS_PATHS {
  template::register_urn \
      -urn      urn:ad:css:monaco:$path \
      -resource /resources/xowf-monaco-plugin/monaco-editor/$path.css
}

foreach path $MONACO_JS_PATHS {
  template::register_urn \
      -urn      urn:ad:js:monaco:$path \
      -resource /resources/xowf-monaco-plugin/monaco-editor/$path.js
}


#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 2
#    indent-tabs-mode: nil
# End:
