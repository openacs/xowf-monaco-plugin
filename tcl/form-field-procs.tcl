::xo::library doc {
  Form field definition for Monaco Editor

  @author Stefan Sobernig
}

:::xo::db::require package xowiki


namespace eval ::xowiki::formfield {

  ########################################################s###
  #
  # ::xowiki::formfield::monaco
  #
  ###########################################################

  Class create monaco -superclass FormField -parameter {
    {language "tcl"}
    {theme "vs"}
    {width 800px}
    {height 600px}
    {minimap true}
    {CSSclass xowf-monaco-container}
  }

  # TODO: Provide for switching between debug (dev) and production (min) mode
  monaco instproc initialize {} {
    if {![info exists :__initialized]} {
      # TODO: Provide for setting data attributes (data-name) on link
      # tags via template::head::add_link
      ::xo::Page requireJS urn:ad:js:jquery
      ::xo::Page requireJS {
        $("<link/>", {
          rel: "stylesheet",
          type: "text/css"
        }).attr("data-name", "vs/editor/editor.main")
        .attr("href","/resources/xowf-monaco-plugin/monaco-editor/dev/vs/editor/editor.main.css")
        .appendTo("head");
      }
      ::xo::Page requireCSS "/resources/xowf-monaco-plugin/plugin.css"
      
      append :style "width: ${:width};" "height: ${:height};"
      set :__initialized 1
    }
  }

  monaco instproc fromBase64 {encValue} {
    # this is the equivalent to b64_to_utf8 at the client side
    if {$encValue ne ""} {
      return [encoding convertfrom utf-8 [binary decode base64 $encValue]]
    }
  }

  monaco instproc pretty_value {} {
    return [:fromBase64 [:value]]
  }

  monaco instproc render_input {} {
    # TODO: Find the appropriate CSP escapes for monaco
    security::csp::require script-src 'unsafe-inline'
    
    # TODO: In disabled mode, one could also use
    # monaco.editor.colorizeElement on a pre element holding the code
    # value
    set readOnly [:is_disabled]
    
    ::html::div [:get_attributes id style {CSSclass class}] {}
    ::html::input -type hidden -name ${:name} -id ${:id}.hidden
    # TODO: URNs
    template::add_body_script -script {var require = { paths: { 'vs': '/resources/xowf-monaco-plugin/monaco-editor/min/vs' } };}
    template::add_body_script -src  "/resources/xowf-monaco-plugin/monaco-editor/min/vs/loader.js"
    template::add_body_script -src  "/resources/xowf-monaco-plugin/monaco-editor/min/vs/editor/editor.main.nls.js"
    template::add_body_script -src  "/resources/xowf-monaco-plugin/monaco-editor/min/vs/editor/editor.main.js"
    # TODO: Use ids accepted by JQuery
    # regsub -all {[.:]} ${:id} "" id
    set currentValue [:value]
    # ns_log notice currentValue=>[:fromBase64 $currentValue]
    template::add_body_script -script [subst -nocommands {
      function utf8_to_b64(str) {
        return window.btoa(unescape(encodeURIComponent(str)));
      }

      function b64_to_utf8(str) {
        return decodeURIComponent(escape(window.atob(str)));
      }
      
      var editor = monaco.editor.create(document.getElementById('${:id}'), {
        language: '${:language}', minimap: {enabled: ${:minimap}}, readOnly: $readOnly, theme: '${:theme}'
      });
      editor.setValue(b64_to_utf8('$currentValue'));
      \$(document).ready(function(){
        \$("form").submit(function(event){
          // alert(utf8_to_b64(editor.getValue()));
          document.getElementById('${:id}.hidden').value = utf8_to_b64(editor.getValue());
        });
      });
    }]
  }

  monaco instproc set_feedback {feedback_mode} {
    next
  }

}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 2
#    indent-tabs-mode: nil
# End:
