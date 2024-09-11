::xo::library doc {
  Form field definition for Monaco Editor

  @author Stefan Sobernig
}

::xo::library require -package xowiki form-field-procs

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
    {readOnly false}
  }

  # TODO: Provide for switching between debug (dev) and production (min) mode
  monaco instproc initialize {} {
    if {![info exists :__initialized]} {
      # TODO: Provide for setting data attributes (data-name) on link
      # tags via template::head::add_link
      ::xo::Page requireJS urn:ad:js:jquery

      # TODO: Switch to URN, once template::head::add_link (see above) is supported
      ::xo::Page requireJS {
        $("<link/>", {
          rel: "stylesheet",
          type: "text/css"
        }).attr("data-name", "vs/editor/editor.main")
        .attr("href","/resources/xowf-monaco-plugin/monaco-editor/min/vs/editor/editor.main.css")
        .appendTo("head");
      }

      #::xo::Page requireCSS "/resources/xowf-monaco-plugin/plugin.css"
      ::xo::Page requireCSS urn:ad:css:monaco:plugin
      #::xo::Page requireJS "/resources/xowf-monaco-plugin/plugin.js"
      ::xo::Page requireJS  urn:ad:js:monaco:plugin

      set :__initialized 1
    }
  }

  monaco instproc fromBase64 {encValue} {
    # this is the equivalent to b64_to_utf8 at the client side
    if {$encValue ne ""} {
      return [encoding convertfrom utf-8 [binary decode base64 $encValue]]
    }
  }

  monaco instproc pretty_value {v} {
    return [:fromBase64 [:value]]
  }

  monaco instproc render_input {} {
    # TODO: Find the appropriate CSP escapes for monaco
    security::csp::require script-src 'unsafe-inline'

    set isDisabled [:is_disabled]

    if {!$isDisabled} {
      append :style "width: ${:width};" "height: ${:height};"
    } else {
      lappend :CSSclass "disabled"
    }

    ::html::div [:get_attributes id style {CSSclass class}] {}

    # Make sure we load the Monaco js only once per request, in case
    # multiple formfields are on the page.
    acs::per_request_cache eval -key xowf-monaco-plugin.monaco-render_input {
      template::add_body_script -script {var require = { paths: { 'vs': '/resources/xowf-monaco-plugin/monaco-editor/min/vs' } };}
      template::add_body_script -src urn:ad:js:monaco:min/vs/loader
      template::add_body_script -src urn:ad:js:monaco:min/vs/editor/editor.main.nls
      template::add_body_script -src urn:ad:js:monaco:min/vs/editor/editor.main
    }

    # TODO: Use ids accepted by JQuery
    # regsub -all {[.:]} ${:id} "" id
    set currentValue [:value]

    if {!$isDisabled} {
      template::add_body_script -script [subst -nocommands {

        xowf.monaco.editors.push(monaco.editor.create(document.getElementById('${:id}'), {
          language: '${:language}', minimap: {enabled: ${:minimap}}, readOnly: ${:readOnly}, theme: '${:theme}'
      }));
        xowf.monaco.editors[xowf.monaco.editors.length-1].setValue(xowf.monaco.b64_to_utf8('$currentValue'));

      }]

      if {!${:readOnly}} {
        ::html::input -type hidden -name ${:name} -id ${:id}.hidden
        template::add_body_script -script {
          $(document).ready(function(){
            $("form").submit(function(event) {
              for (var i = 0; i < xowf.monaco.editors.length ; i++)  {
               var e = xowf.monaco.editors[i];
               if (!e.getRawOptions()["readOnly"]) {
                 var hiddenId = e.getDomNode().parentNode.id + ".hidden";
                 var hiddenEl = document.getElementById(hiddenId);
                 if (hiddenEl != null) {
                   hiddenEl.value = xowf.monaco.utf8_to_b64(e.getValue());
                 }
               }
             }
            });
          });
        }
      }
    } else {
      template::add_body_script -script [subst {
        monaco.editor.colorize(xowf.monaco.b64_to_utf8('$currentValue'), '${:language}')
        .then(html => document.getElementById('${:id}').innerHTML = html);
      }]
    }
  }

  monaco instproc set_feedback {feedback_mode} {
    next
  }

  ########################################################s###
  #
  # ::xowiki::formfield::monaco_html_sandbox
  #
  ###########################################################

  Class create monaco_html_sandbox -superclass monaco -ad_doc {
    This class provides an HTML sandbox formfield powered by the Monaco
    code editor set to HTML mode. The code inputted in the editor is
    rendered as a standalone document inside an iframe, or in a
    separate window.

    The formfield also supports live preview, updated whenever the
    code has changed. The preview can be shown alongside the code
    (inline), in a separate window, or both.
  } -parameter {
    {preview_window true}
    {preview_inline true}
  }

  monaco_html_sandbox instproc initialize args {
    set :language html
    next
  }

  monaco_html_sandbox ad_instproc -private render_input args {
    Displays the editor. It will also render the preview according to
    parameters and make sure that this is kept up to date whenever the
    code in the editor changes.
  } {
    # No previews, just show the code editor
    if {!${:preview_inline} && !${:preview_window}} {
      return [next]
    }

    # This element is invisible and contains the base64 encoded value
    # of the formfield, which we use to initialize the previews. One
    # could also do it using the editor api, but we do not have one in
    # case of a readonly field or when we render this field in display
    # mode.
    ::html::template -id "${:id}-srcdoc" style "display:none;" {
      ::html::t [:value]
    }

    ::html::div -id ${:id}-container style "display:flex; flex-wrap:wrap;" {
      ::html::div -id ${:id}-code {
        next
      }
      if {${:preview_inline}} {
        ::html::div -id ${:id}-preview {
          ::html::iframe -id ${:id}-iframe -style "width: ${:width}; height: ${:height};"
        }
      }
    }
    if {${:preview_window}} {
      ::html::div {
        ::html::a -href "#" -id ${:id}-fullscreen-btn class "btn btn-default" {
          html::t [_ xowf-monaco-plugin.open_preview_in_an_own_window]
        }
      }
    }

    template::add_body_handler -event load -script [subst -nocommands {
      var srcDoc = document.getElementById('${:id}-srcdoc');
      var page = xowf.monaco.b64_to_utf8(srcDoc.innerHTML);

      // When clicking on the fullscreen button, open a new window
      // insert an iframe and set its content as our markup
      var fullscreenWindowHandle;
      var fullscreenIframe;
      var fullscreenBtn = document.getElementById('${:id}-fullscreen-btn');
      if (fullscreenBtn) {
        fullscreenBtn.addEventListener("click", function(e) {
          if ((!fullscreenWindowHandle || fullscreenWindowHandle.closed) && page) {
            fullscreenWindowHandle = window.open();
            fullscreenWindowHandle.document.write('<iframe src="" style="width: 100%; height: 100%; border: 0;" allowfullscreen></iframe>');
            fullscreenIframe = fullscreenWindowHandle.document.querySelector('iframe');
            fullscreenIframe.srcdoc = page;
          }
        });
      }

      var iframe = document.getElementById('${:id}-iframe');
      if (iframe) {
        iframe.srcdoc = page;
      }

      // If we have an editor (field is writable), find it and listen
      // to change events, every time updating the preview either inline
      // or in the window.
      for (var i = 0; i < xowf.monaco.editors.length ; i++)  {
        var e = xowf.monaco.editors[i];
        var hiddenId = e.getDomNode().parentNode.id + ".hidden";
        if (hiddenId === '${:id}.hidden') {
          e.onDidChangeModelContent((event) => {
            page = e.getValue();
            if (iframe) {
              iframe.srcdoc = page;
            }
            if (fullscreenWindowHandle && !fullscreenWindowHandle.closed) {
              fullscreenIframe.srcdoc = page;
            }
          });
        }
      }
    }]
  }

  monaco_html_sandbox ad_instproc -private pretty_value args {
    Display the HTML inline or as an own page by clicking a button.

    @return HTML
  } {
    template::add_body_handler -event load -script [subst -nocommands {
      var srcDoc = document.getElementById('${:id}-srcdoc');
      var page = xowf.monaco.b64_to_utf8(srcDoc.innerHTML);

      var iframe = document.getElementById('${:id}-iframe');
      iframe.srcdoc = page;

      var fullscreenWindowHandle;
      var fullscreenBtn = document.getElementById('${:id}-fullscreen-btn');
      fullscreenBtn.addEventListener("click", function(e) {
        e.preventDefault();
        if (!fullscreenWindowHandle || fullscreenWindowHandle.closed) {
          fullscreenWindowHandle = window.open();
          fullscreenWindowHandle.document.write(page);
        }
      });
    }]
    set base64 [:value]
    return [subst -nocommands {
      <template id="${:id}-srcdoc" style="display:none;">$base64</template>
      <div>
         <iframe style="width: ${:width}; height: ${:height};" id="${:id}-iframe"></iframe>
      </div>
      <div>
         <a class="btn btn-default"
            href="#"
            id="${:id}-fullscreen-btn">#xowf-monaco-plugin.open_preview_in_an_own_window#</a>
      </div>
    }]
  }

}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 2
#    indent-tabs-mode: nil
# End:
