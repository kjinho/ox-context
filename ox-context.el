;;; ox-context --- Org exporter for ConTeXt -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Jason Ross
;; Author: Jason Ross <jasonross1024 at gmail dot com>
;; Keywords: org, ConTeXt
;; Version: 0.1
;; URL: https://github.com/Jason-S-Ross/ox-context
;; Package-Requires: ((emacs "26") (org "9"))

;; This is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; TODO Set indentation level for content
;; This can be done by putting content into a temporary buffer, setting
;; (context-mode), and calling (indent-region (point-min) (point-max)).
;; However, this needs to ignore code blocks, so it must be done carefully.
;;
;;; Commentary:

;; This library implements a ConTeXt back-end for Org generic exporter.
;; * Export Commands
;; - `org-context-export-as-context' :: Export as ConTeXt to a temporary
;;   buffer. Do not create a file.
;; - `org-context-export-to-context' :: Export as ConTeXt to a file with
;;   a ~.mkiv~ extension. For ~myfile.org~, exports as ~myfile.mkiv~,
;;   overwriting without warning.
;; - `org-context-export-to-pdf' :: Export as a ConTeXt file and convert it
;;   to pdf.
;;
;; * Document-level Keywords
;;   The following buffer keywords are added:
;;   - ~CONTEXT_HEADER~ :: Adds literal ConTeXt to the document preamble
;;     before custom command definitions.
;;   - ~CONTEXT_HEADER_EXTRA~ :: Adds literal ConTeXt to the document preamble
;;     after custom command definitions.
;;   - ~CONTEXT_PRESET~ :: Specifies the document preset to use from
;;     `org-context-presets-alist'. See `org-context-preset'.
;;     Presets are the primary method used by `ox-context' to specify document
;;     structure.
;;   - ~DATE~ :: Sets the `metadata:date' ConTeXt document metadata variable. Can
;;     be any valid ConTeXt command. If blank, ~\currentdate~ is used.
;;   - ~DESCRIPTION~ :: Sets the `metadata:description' ConTeXt document metadata value.
;;   - ~KEYWORDS~ :: Sets the `metadata:keywords' ConTeXt document metadata value.
;;   - ~LANGUAGE~ :: Sets the `metadata:language' ConTeXt document metatdata value. Adds
;;     `\language[%s]' to the preamble.
;;   - ~SUBJECT~ :: Sets the `metadata:subject' ConTeXt document metadata value.
;;   - ~SUBTITLE~ :: Sets the `metadata:subtitle' ConTeXt document metadata value.
;;   - ~TABLE_LOCATION~ :: Specifies ~location~ key for the float wrapping the table.
;;     See `org-context-table-location'.
;;   - ~TABLE_HEAD~ :: Specifies the ~header~ key for the ~\startxtable~ command.
;;     ~repeat~ is supported; see ConTeXt documentation for other values
;;     (none known as of this writing).
;;     See `org-context-table-head'.
;;   - ~TABLE_FOOT~ :: Specifies the ~footer~ key for the ~\startxtable~ command.
;;     ~repeat~ is supported; see ConTeXt documentation for other values
;;     (none known as of this writing).
;;     See `org-context-table-foot'.
;;   - ~TABLE_OPTION~ :: Specifies the ~option~ key for the ~\startxtable~ command.
;;     As of this writing, the values ~stretch~, ~width~, and ~tight~ are supported.
;;     See `org-context-table-option'.
;;   - ~TABLE_SPLIT~ :: If "yes", tables are split across pages.
;;     See `org-context-table-split'.
;;   - ~TABLE_STYLE~ :: Specifies a named ConTeXt table style to pass to the
;;     ~\startxtable~ command, defined with the ~\setupxtable~ command.
;;     See `org-context-table-style'.
;;   - ~TABLE_FLOAT~ :: Specifies a list of arguments to pass to the
;;     ~startplacetable~ command, overriding any arguments determined
;;     automatically by other options.
;;     See `org-context-table-float'.
;;
;;
;; * Options
;;   The following additional items are handled from the OPTIONS keyword:
;;   - ~syntax~ :: If ~vim~, use the ~t-vim~ ConTeXt module for syntax
;;     highlighting. Otherwise, don't highlight source code.
;;   - ~numeq~ :: if non-nil, equations are numbered.
;; * In-text Keywords
;;   The following additional keywords are supported to add content in text:
;;   - ~ATTR_CONTEXT~ :: Adds a plist of context-dependent configuration options
;;     for the following element.
;;   - ~INDEX~ :: Adds a term to the default ConTeXt index.
;;   - ~CINDEX~ :: Adds an `OrgConcept' keyword. Added for compatibility
;;     with ~texinfo~ concept keywords.
;;   - ~FINDEX~ :: Adds an `OrgFunction' keyword. Added for compatibility
;;     with ~texinfo~ function keywords.
;;   - ~KINDEX~ :: Adds an `OrgKeystroke' keyword. Added for compatibility
;;     with ~texinfo~ keystroke keywords.
;;   - ~PINDEX~ :: Adds an `OrgProgram' keyword. Added for compatibility
;;     with ~texinfo~ program keywords.
;;   - ~TINDEX~ :: Adds an `OrgDataType' keyword. Added for compatibility
;;     with ~texinfo~ data-type keywords.
;;   - ~VINDEX~ :: Adds an `OrgVariable' keyword. Added for compatibility
;;     with ~texinfo~ variable keywords.
;;   - ~CONTEXT~ :: Adds raw ConTeXt at this point.
;;   - ~TOC~ :: Adds a table of contents or index at this point. Supports the
;;     following values:
;;     - ~tables~ :: Adds a list of tables.
;;     - ~figures~ :: Adds a list of figures.
;;     - ~equations~ :: Adds a list of equations.
;;     - ~references~ :: Adds a bibliography.
;;     - ~definitions~ :: Places the default index.
;;     - ~headlines~ :: Places a table of contents. Additional options are supported:
;;       - /depth/ :: An integer in the command will limit the toc to this depth.
;;       - ~local~ :: If present, limits the scope of the toc to this section.
;;     - ~listings~ :: Adds a list of code listings.
;;     - ~verses~ :: Adds a list of verse blocks.
;;     - ~quotes~ :: Adds a list of quote blocks.
;;     - ~examples~ :: Adds a list of example blocks.
;;     - ~cp~ :: Adds an index of concepts defined with the ~CINDEX~ keyword.
;;     - ~fn~ :: Adds an index of functions defined with the ~FINDEX~ keyword.
;;     - ~ky~ :: Adds an index of keystrokes defined with the ~KINDEX~ keyword.
;;     - ~pg~ :: Adds an index of programs defined with the ~PINDEX~ keyword.
;;     - ~tp~ :: Adds an index of data types defined with the ~TINDEX~ keyword.
;;     - ~vr~ :: Adds an index of variables defined with the ~VINDEX keyword.
;; * Additional Inline Configuration of Elements
;;   The following elements support additional inline configuration through
;;   the ~ATTR_CONTEXT~ keyword.
;; ** Inline images
;;    Inline images support configuration for the following keys:
;;    - `:float' :: One of the following values:
;;      - ~wrap~ :: Places the image in the text, flowing text around it.
;;      - ~sideways~ :: Places the image rotated 90 degrees.
;;      - ~multicolumn~ :: Places the image to fit in the column instead of the page.
;;    - `:width' :: A ConTeXt expression for the desired image width.
;;      Otherwise, uses `org-context-image-default-width'.
;;    - `:height' :: A ConTeXt expression for the desired image height.
;;      Otherwise, uses `org-context-image-default-height'.
;;    - `:placement' :: Options to pass to the ~\startplacefigure~ command
;;      for the ~location~ key.
;; ** Tables
;; *** Global Options
;;     Tables support configuration for the following keys:
;;     - `:location' :: Overrides the ~TABLE_LOCATION~ keyword for this table.
;;     - `:header' :: Overrides the ~TABLE_HEAD~ keyword for this table.
;;     - `:footer' :: Overrides the ~TABLE_FOOT~ keyword for this table.
;;     - `:option' :: Overrides the ~TABLE_OPTION~ keyword for this table.
;;     - `:split' :: Overrides the ~TABLE_SPLIT~ keyword for this table.
;;     - `:table-style' :: Overrides the ~TABLE_STYLE~ keyword for this table.
;;     - `:float-style' :: Overrides the ~TABLE_FLOAT~ keyword for this table.
;;
;;
;; *** Content Options
;;     Table cells at various positions can be styled with additional keys.
;;     Values passed to these keys will be provided as arguments to
;;     the ~\startxcell~ macro.
;;     The locations of cells to style are specified by the following keys:
;;     - `:n' :: "North"; the top row of cells.
;;       Defaults to `org-context-table-toprow-style'.
;;     - `:e' :: "East"; the right-most column of cells.
;;       Defaults to `org-context-table-rightcol-style'.
;;     - `:w' :: "West"; the left-most column of cells.
;;       Defaults to `org-context-table-leftcol-style'.
;;     - `:s' :: "South"; the bottom row of cells.
;;       Defaults to `org-context-table-bottomrow-style'.
;;     - `:nw' :: "North-West"; the cell in the upper-left corner.
;;       Defaults to `org-context-table-topleft-style'.
;;     - `:ne' :: "North-East"; the cell in the upper-right.
;;       Defaults to `org-context-table-topright-style'.
;;     - `:sw' :: "South-West"; the cell in the lower-left.
;;       Defaults to `org-context-table-bottomleft-style'.
;;     - `:se' :: "South-East"; the cell in the lower-right.
;;       Defaults to `org-context-table-bottomright-style'.
;;     - `:cgs' :: "Column Group Start"; the cells in the column before a
;;       column group boundary.
;;       Defaults to `org-context-table-colgroup-start-style'.
;;     - `:cge' :: "Column Group End"; the cells in the column after a
;;       column group boundary.
;;       Defaults to `org-context-table-colgroup-end-style'.
;;     - `:rgs' :: "Row Group Start"; the row before a row group boundary.
;;       Defaults to `org-context-table-rowgroup-start-style'.
;;     - `:rge' :: "Row Group End"; the row after a row group boundary.
;;       Defaults to `org-context-table-rowgroup-end-style'.
;;     - `:h' :: "Header"; the cells in the header. Defaults to
;;       `org-context-table-header-style'.
;;     - `:f' :: "Footer"; the cells in the footer. Defaults to
;;       `org-context-table-footer-style'.
;;       NOTE: If this key is present, tables will attempt to use footers.
;;     - `:b' :: "Body"; the cells in the body. Defaults to
;;       `org-context-table-body-style'.
;;     - `:ht' :: "Header Top"; the cells in the first row of header rows.
;;       Defaults to `org-context-table-header-top-style'
;;     - `:hm' :: "Header Mid"; the cells in header rows not in the top or bottom.
;;       Defaults to `org-context-table-header-mid-style'.
;;     - `:hb' :: "Header Bottom"; the cells in the last row of the header rows.
;;       Defaults to `org-context-table-header-bottom-style'.
;;     - `:ft' :: "Footer Top"; the cells in the last row of footer rows.
;;       Defaults to `org-context-table-footer-top-style'.
;;     - `:fm' :: "Footer Mid"; the cells in the footer rows not in the top or bottom.
;;       Defaults to `org-context-table-footer-mid-style'.
;;
;;
;;
;;; Code:

;;; Dependencies
(require 'cl-lib)
(require 'ox)
(require 'ox-org)
(require 'seq)
(require 'subr-x)
(require 'context)
(require 'texinfmt) ;; Needed for texinfo-part-of-para-regexp

;;; Define Back-end
(org-export-define-backend 'context
  '((bold . org-context-bold)
    (center-block . org-context-center-block)
    (clock . org-context-clock)
    (code . org-context-code)
    (drawer . org-context-drawer)
    (dynamic-block . org-context-dynamic-block)
    (entity . org-context-entity)
    (example-block . org-context-example-block)
    (export-block . org-context-export-block)
    (export-snippet . org-context-export-snippet)
    (fixed-width . org-context-fixed-width)
    (footnote-reference . org-context-footnote-reference)
    (headline . org-context-headline)
    (horizontal-rule . org-context-horizontal-rule)
    (inline-src-block . org-context-inline-src-block)
    (inlinetask . org-context-inlinetask)
    (inner-template . org-context-inner-template)
    (italic . org-context-italic)
    (item . org-context-item)
    (keyword . org-context-keyword)
    (latex-environment . org-context-latex-environment)
    (latex-fragment . org-context-latex-fragment)
    (line-break . org-context-line-break)
    (link . org-context-link)
    (node-property . org-context-node-property)
    (paragraph . org-context-paragraph)
    (plain-list . org-context-plain-list)
    (plain-text . org-context-plain-text)
    (planning . org-context-planning)
    (property-drawer . org-context-property-drawer)
    (quote-block . org-context-quote-block)
    (radio-target . org-context-radio-target)
    (section . org-context-section)
    (special-block . org-context-special-block)
    (src-block . org-context-src-block)
    (statistics-cookie . org-context-statistics-cookie)
    (strike-through . org-context-strike-through)
    (subscript . org-context-subscript)
    (superscript . org-context-superscript)
    (table . org-context-table)
    (table-cell . org-context-table-cell)
    (table-row . org-context-table-row)
    (target . org-context-target)
    (template . org-context-template)
    (timestamp . org-context-timestamp)
    (underline . org-context-underline)
    (verbatim . org-context-verbatim)
    (verse-block . org-context-verse-block)
    ;;;; Pseudo objects and elements.
    (latex-math-block . org-context-math-block))
  :menu-entry
  '(?C "Export to ConTeXt"
       ((?c "As ConTeXt file" org-context-export-to-context)
        (?C "As ConTeXt buffer" org-context-export-as-context)
        (?p "As PDF file" org-context-export-to-pdf)
        (?o "As PDF file and open"
            (lambda (a s v b)
              (if a (org-context-export-to-pdf t s v b)
                (org-open-file (org-context-export-to-pdf s v b)))))))
 :filters-alist '((:filter-options . org-context-math-block-options-filter)
                  (:filter-paragraph . org-context-clean-invalid-line-breaks)
                  (:filter-parse-tree  org-context-math-block-tree-filter
                                       org-context-texinfo-tree-filter)
                  (:filter-verse-block . org-context-clean-invalid-line-breaks))
 :options-alist '((:context-block-source-environment nil nil org-context-block-source-environment)
                  (:context-blockquote-environment nil nil org-context-blockquote-environment)
                  (:context-bullet-off-command nil nil org-context-bullet-off-command)
                  (:context-bullet-on-command nil nil org-context-bullet-on-command)
                  (:context-bullet-trans-command nil nil org-context-bullet-trans-command)
                  (:context-clock-command nil nil org-context-clock-command)
                  (:context-description-command nil nil org-context-description-command)
                  (:context-drawer-command nil nil org-context-drawer-command)
                  (:context-enumerate-blockquote-empty-environment nil nil org-context-enumerate-blockquote-empty-environment)
                  (:context-enumerate-blockquote-environment nil nil org-context-enumerate-blockquote-environment)
                  (:context-enumerate-example-empty-environment nil nil org-context-enumerate-example-empty-environment)
                  (:context-enumerate-example-environment nil nil org-context-enumerate-example-environment)
                  (:context-enumerate-listing-empty-environment nil nil org-context-enumerate-listing-empty-environment)
                  (:context-enumerate-listing-environment nil nil org-context-enumerate-listing-environment)
                  (:context-enumerate-verse-empty-environment nil nil org-context-enumerate-verse-empty-environment)
                  (:context-enumerate-verse-environment nil nil org-context-enumerate-verse-environment)
                  (:context-example-environment nil nil org-context-example-environment)
                  (:context-export-quotes-alist nil nil org-context-export-quotes-alist)
                  (:context-fixed-environment nil nil org-context-fixed-environment)
                  (:context-float-default-placement nil nil org-context-float-default-placement)
                  (:context-format-clock-function nil nil org-context-format-clock-function)
                  (:context-format-drawer-function nil nil org-context-format-drawer-function)
                  (:context-format-headline-function nil nil org-context-format-headline-function)
                  (:context-format-inlinetask-function nil nil org-context-format-inlinetask-function)
                  (:context-format-timestamp-function nil nil org-context-format-timestamp-function)
                  (:context-header "CONTEXT_HEADER" nil nil newline)
                  (:context-header-extra "CONTEXT_HEADER_EXTRA" nil nil newline)
                  (:context-headline-command nil nil org-context-headline-command)
                  (:context-highlighted-langs nil nil org-context-highlighted-langs-alist)
                  (:context-image-default-height nil nil org-context-image-default-height)
                  (:context-image-default-option nil nil org-context-image-default-option)
                  (:context-image-default-scale nil nil org-context-image-default-scale)
                  (:context-image-default-width nil nil org-context-image-default-width)
                  (:context-inline-image-rules nil nil org-context-inline-image-rules)
                  (:context-inline-source-environment nil nil org-context-inline-source-environment)
                  (:context-inlinetask-command nil nil org-context-inlinetask-command)
                  (:context-inner-templates nil nil org-context-inner-templates-alist)
                  (:context-node-property-command nil nil org-context-node-property-command)
                  (:context-number-equations nil "numeq" org-context-number-equations)
                  (:context-planning-command nil nil org-context-planning-command)
                  (:context-preset "CONTEXT_PRESET" nil org-context-preset t)
                  (:context-presets nil nil org-context-presets-alist)
                  (:context-property-drawer-environment nil nil org-context-property-drawer-environment)
                  (:context-snippet "CONTEXT_SNIPPET" nil nil split)
                  (:context-snippets nil nil org-context-snippets-alist)
                  (:context-source-label nil nil org-context-source-label)
                  (:context-syntax-engine nil "syntax" org-context-syntax-engine)
                  (:context-table-body-style nil nil org-context-table-body-style)
                  (:context-table-bottomleft-style nil nil org-context-table-bottomleft-style)
                  (:context-table-bottomright-style nil nil org-context-table-bottomright-style)
                  (:context-table-bottomrow-style nil nil org-context-table-bottomrow-style)
                  (:context-table-colgroup-end-style nil nil org-context-table-colgroup-end-style)
                  (:context-table-colgroup-start-style nil nil org-context-table-colgroup-start-style)
                  (:context-table-footer-bottom-style nil nil org-context-table-footer-bottom-style)
                  (:context-table-footer-mid-style nil nil org-context-table-footer-mid-style)
                  (:context-table-footer-style nil nil org-context-table-footer-style)
                  (:context-table-footer-top-style nil nil org-context-table-footer-top-style)
                  (:context-table-header-bottom-style nil nil org-context-table-header-bottom-style)
                  (:context-table-header-mid-style nil nil org-context-table-header-mid-style)
                  (:context-table-header-style nil nil org-context-table-header-style)
                  (:context-table-header-top-style nil nil org-context-table-header-top-style)
                  (:context-table-leftcol-style nil nil org-context-table-leftcol-style)
                  (:context-table-rightcol-style nil nil org-context-table-rightcol-style)
                  (:context-table-rowgroup-end-style nil nil org-context-table-rowgroup-end-style)
                  (:context-table-rowgroup-start-style nil nil org-context-table-rowgroup-start-style)
                  (:context-table-topleft-style nil nil org-context-table-topleft-style)
                  (:context-table-topright-style nil nil org-context-table-topright-style)
                  (:context-table-toprow-style nil nil org-context-table-toprow-style)
                  (:context-table-location "TABLE_LOCATION" nil org-context-table-location parse)
                  (:context-table-header "TABLE_HEAD" nil org-context-table-head parse)
                  (:context-table-footer "TABLE_FOOT" nil org-context-table-foot parse)
                  (:context-table-option "TABLE_OPTION" nil org-context-table-option parse)
                  (:context-table-style "TABLE_STYLE" nil org-context-table-style parse)
                  (:context-table-float-style "TABLE_FLOAT" nil org-context-table-float-style parse)
                  (:context-table-split "TABLE_SPLIT" nil org-context-table-split parse)
                  (:context-texinfo-indices nil nil org-context-texinfo-indices-alist)
                  (:context-text-markup-alist nil nil org-context-text-markup-alist)
                  (:context-toc-command-alist nil nil org-context-toc-command-alist)
                  (:context-toc-title-command nil nil org-context-toc-title-command)
                  (:context-verse-environment nil nil org-context-verse-environment)
                  (:context-vim-langs-alist nil nil org-context-vim-langs-alist)
                  (:date "DATE" nil "\\currentdate" parse)
                  (:description "DESCRIPTION" nil nil parse)
                  (:keywords "KEYWORDS" nil nil parse)
                  (:subject "SUBJECT" nil nil parse)
                  (:subtitle "SUBTITLE" nil nil parse)))

;;; Constants

(defconst org-context-latex-math-environments-re
  (format
   "\\`[ \t]*\\\\begin{%s\\*?}"
   (regexp-opt
    '("equation" "eqnarray" "math" "displaymath"
      "align"  "gather" "multline" "flalign"  "alignat"
      "xalignat" "xxalignat"
      "subequations"
      ;; breqn
      "dmath" "dseries" "dgroup" "darray"
      ;; empheq
      "empheq")))
  "Regexp of LaTeX math environments.")
;;; User configuration variables

(defgroup org-export-context nil
  "Options for exporting to ConTeXt."
  :tag "Org ConTeXt"
  :group 'org-export)

;;;; ConTeXt environments

;;;;; Table Styles

(defcustom org-context-table-body-style '("OrgTableBody" . "")
  "The default style name for the body row group in tables.

Cons list of NAME, DEF. If DEF is nil, an empty definition is created."
  :group 'org-export-context
  :type '(cons (string :tag "Style Name")
               (string :tag "Style Definition")))

(defcustom org-context-table-bottomleft-style '("OrgTableBottomLeftCell" . "")
  "The default style name for the bottom left cell in tables.

Cons list of NAME, DEF. If DEF is nil, an empty definition is created."
  :group 'org-export-context
  :type '(cons (string :tag "Style Name")
               (string :tag "Style Definition")))

(defcustom org-context-table-bottomright-style '("OrgTableBottomRightCell" . "")
  "The default style name for the bottom right cell in tables.

Cons list of NAME, DEF. If DEF is nil, an empty definition is created."
  :group 'org-export-context
  :type '(cons (string :tag "Style Name")
               (string :tag "Style Definition")))

(defcustom org-context-table-bottomrow-style '("OrgTableBottomRow" . "")
  "The default style name for the bottom row in tables.

Cons list of NAME, DEF. If DEF is nil, an empty definition is created."
  :group 'org-export-context
  :type '(cons (string :tag "Style Name")
               (string :tag "Style Definition")))

(defcustom org-context-table-colgroup-end-style '("OrgTableColGroupEnd" . "")
  "The default style name for columns ending column groups in tables.

Cons list of NAME, DEF. If DEF is nil, an empty definition is created."
  :group 'org-export-context
  :type '(cons (string :tag "Style Name")
               (string :tag "Style Definition")))

(defcustom org-context-table-colgroup-start-style '("OrgTableColGroupStart" . "")
  "The default style name for columns starting column groups in tables.

Cons list of NAME, DEF. If DEF is nil, an empty definition is created."
  :group 'org-export-context
  :type '(cons (string :tag "Style Name")
               (string :tag "Style Definition")))

(defcustom org-context-table-footer-bottom-style '("OrgTableFooterBottom" . "")
  "The default style name for the bottom row in the footer row group in tables.

Cons list of NAME, DEF. If DEF is nil, an empty definition is created."
  :group 'org-export-context
  :type '(cons (string :tag "Style Name")
               (string :tag "Style Definition")))

(defcustom org-context-table-footer-mid-style '("OrgTableFooterMid" . "")
  "The default style name for footer rows where the footer is only one row.

Cons list of NAME, DEF. If DEF is nil, an empty definition is created."
  :group 'org-export-context
  :type '(cons (string :tag "Style Name")
               (string :tag "Style Definition")))

(defcustom org-context-table-footer-style '("OrgTableFooter" . "")
  "The default style name for the footer row group in tables.

Cons list of NAME, DEF. If DEF is nil, an empty definition is created."
  :group 'org-export-context
  :type '(cons (string :tag "Style Name")
               (string :tag "Style Definition")))

(defcustom org-context-table-footer-top-style '("OrgTableFooterTop" . "")
  "The default style name for the top row in the footer row group in tables.

Cons list of NAME, DEF. If DEF is nil, an empty definition is created."
  :group 'org-export-context
  :type '(cons (string :tag "Style Name")
               (string :tag "Style Definition")))

(defcustom org-context-table-header-bottom-style '("OrgTableHeaderBottom" . "")
  "The default style name for the bottom row in the header row group in tables.

Cons list of NAME, DEF. If DEF is nil, an empty definition is created."
  :group 'org-export-context
  :type '(cons (string :tag "Style Name")
               (string :tag "Style Definition")))

(defcustom org-context-table-header-mid-style '("OrgTableHeaderMid" . "")
  "The default style name for header rows where the header is only one row.

Cons list of NAME, DEF. If DEF is nil, an empty definition is created."
  :group 'org-export-context
  :type '(cons (string :tag "Style Name")
               (string :tag "Style Definition")))

(defcustom org-context-table-header-style '("OrgTableHeader" . "")
  "The default style name for the header row group in tables.

Cons list of NAME, DEF. If DEF is nil, an empty definition is created."
  :group 'org-export-context
  :type '(cons (string :tag "Style Name")
               (string :tag "Style Definition")))

(defcustom org-context-table-header-top-style '("OrgTableHeaderTop" . "")
  "The default style name for the top row in the header row group in tables.

Cons list of NAME, DEF. If DEF is nil, an empty definition is created."
  :group 'org-export-context
  :type '(cons (string :tag "Style Name")
               (string :tag "Style Definition")))

(defcustom org-context-table-leftcol-style '("OrgTableLeftCol" . "")
  "The default style name for the left column in tables.

Cons list of NAME, DEF. If DEF is nil, an empty definition is created."
  :group 'org-export-context
  :type '(cons (string :tag "Style Name")
               (string :tag "Style Definition")))

(defcustom org-context-table-rightcol-style '("OrgTableRightCol" . "")
  "The default style name for the right column in tables.

Cons list of NAME, DEF. If DEF is nil, an empty definition is created."
  :group 'org-export-context
  :type '(cons (string :tag "Style Name")
               (string :tag "Style Definition")))

(defcustom org-context-table-rowgroup-start-style '("OrgTableRowGroupStart" . "")
  "The default style name for rows starting row groups in tables.

Cons list of NAME, DEF. If DEF is nil, an empty definition is created."
  :group 'org-export-context
  :type '(cons (string :tag "Style Name")
               (string :tag "Style Definition")))

(defcustom org-context-table-rowgroup-end-style '("OrgTableRowGroupEnd" . "")
  "The default style name for rows ending row groups in tables.

Cons list of NAME, DEF. If DEF is nil, an empty definition is created."
  :group 'org-export-context
  :type '(cons (string :tag "Style Name")
               (string :tag "Style Definition")))

(defcustom org-context-table-topleft-style '("OrgTableTopLeftCell" . "")
  "The default style name for the top left cell in tables.

Cons list of NAME, DEF. If DEF is nil, an empty definition is created."
  :group 'org-export-context
  :type '(cons (string :tag "Style Name")
               (string :tag "Style Definition")))

(defcustom org-context-table-topright-style '("OrgTableTopRightCell" . "")
  "The default style name for the top right cell in tables.

Cons list of NAME, DEF. If DEF is nil, an empty definition is created."
  :group 'org-export-context
  :type '(cons (string :tag "Style Name")
               (string :tag "Style Definition")))

(defcustom org-context-table-toprow-style '("OrgTableTopRow" . "")
  "The default style name for the top row in tables.

Cons list of NAME, DEF. If DEF is nil, an empty definition is created."
  :group 'org-export-context
  :type '(cons (string :tag "Style Name")
               (string :tag "Style Definition")))



;;;;; Element Environments

;; These environments wrap block elements to provide the core implementation.

(defcustom org-context-blockquote-environment
  '("OrgBlockQuote" . "\\definenarrower[OrgBlockQuote][left=2em,right=2em]")
  "The environment name of the block quote environment.

Cons list of NAME, DEF. If nil, block quotes aren't delimited."
  :group 'org-export-context
  :type '(cons (string :tag "Environment Name")
               (string :tag "Environment Definition")))

(defcustom org-context-example-environment
  '("OrgExample" . "\\definetyping[OrgExample][escape=yes]")
  "The environment name of the example environment.

Cons list of NAME, DEF. If NAME is nil, examples are delimited
in a typing environment. If DEF is nil, a default typing environment
called NAME is created."
  :group 'org-export-context
  :type '(cons (string :tag "Environment Name")
               (string :tag "Environment Definition")))

(defcustom org-context-fixed-environment
  '("OrgFixed" . "\\definetextbackground
  [OrgFixedBackground]
  [backgroundcolor=white,
   topoffset=1ex,
   leftoffset=1em,
   framecolor=black,
   location=always,
   before={\\blank[line]},
   after={\\blank[line]}]
\\definetyping
  [OrgFixed]
  [before={\\starttextbackground[OrgFixedBackground]},
   after={\\stoptextbackground}]")
  "The environment name of the fixed-width environment.

Cons list of NAME, DEF. If nil, examples are enclosed in
\"\\starttyping\" / \"\\stoptying\""
  :group 'org-export-context
  :type '(cons (string :tag "Environment Name")
               (string :tag "Environment Definition")))

(defcustom org-context-property-drawer-environment
  '("OrgPropDrawer" . "\\definestartstop[OrgPropDrawer]
  [before={\\startframedtext[frame=on,width=broad]},
   after={\\stopframedtext}]")
  "The environment name of the property drawer environment.

Cons list of NAME, DEF. If nil, examples are enclosed in
\"\\startframedtext\" / \"\\stopframedtext\""
  :group 'org-export-context
  :type '(cons (string :tag "Environment Name")
               (string :tag "Environment Definition")))

(defcustom org-context-inline-source-environment
  '("OrgInlineSrc" . "\\definetype[OrgInlineSrc]")
  "The environment name of the inline source environment.

Cons list of NAME, DEF. If nil, examples are enclosed in
\"\\starttyping\" / \"\\stoptying\""
  :group 'org-export-context
  :type '(cons (string :tag "Environment Name")
               (string :tag "Environment Definition")))

(defcustom org-context-block-source-environment
  '("OrgBlkSrc" . "\\definetyping[OrgBlkSrc][escape=yes]")
  "The environment name of the block source environment.

Cons list of NAME, DEF. If nil, examples are enclosed in
\"\\starttyping\" / \"\\stoptying\""
  :group 'org-export-context
  :type '(cons (string :tag "Environment Name")
               (string :tag "Environment Definition")))

(defcustom org-context-verse-environment
  '("OrgVerse" . "\\definelines[OrgVerse]")
  "The environment name of the verse environment.

Cons list of NAME, DEF. If nil, verses aren't delimited."
  :group 'org-export-context
  :type '(cons (string :tag "Environment Name")
               (string :tag "Environment Definition")))


;;;;; Enumeration environments

;; These environments wrap around element environments to allow them
;; to be enumerated in listings.

(defcustom org-context-enumerate-blockquote-empty-environment
  '("OrgBlockQuoteEnumEmpty" . "\\defineenumeration
  [OrgBlockQuoteEnumEmpty]
  [alternative=empty
   margin=0pt]")
  "The enumeration of the unlabelled blockquote environment.

Cons list of NAME, DEF. By default, shares a counter with
`org-context-enumerate-blockquote-environment'. If nil, block
quotes are not wrapped in an enumeration"
  :group 'org-export-context
  :type '(cons (string :tag "Environment Name")
               (string :tag "Environment Definition")))

(defcustom org-context-enumerate-blockquote-environment
  '("OrgBlockQuoteEnum" . "\\defineenumeration
  [OrgBlockQuoteEnum]
  [OrgBlockQuoteEnumEmpty]
  [title=yes,
   text=Quote,
   alternative=top]")
  "The enumeration of the blockquote environment.

Cons list of NAME, DEF. By default, shares a counter with
`org-context-enumerate-blockquote-empty-environment'. If nil,
block quotes are not wrapped in an enumeration"
  :group 'org-export-context
  :type '(cons (string :tag "Environment Name")
               (string :tag "Environment Definition")))

(defcustom org-context-enumerate-example-empty-environment
  '("OrgExampleEnumEmpty" . "\\defineenumeration
  [OrgExampleEnumEmpty]
  [alternative=empty,
   margin=0pt]")
  "The enumeration of the unlabelled example environment.

Cons list of NAME, DEF. By default, shares a counter with
`org-context-enumerate-example-environment'. If nil, examples are
not wrapped in an enumeration"
  :group 'org-export-context
  :type '(cons (string :tag "Environment Name")
               (string :tag "Environment Definition")))

(defcustom org-context-enumerate-example-environment
  '("OrgExampleEnum" . "\\defineenumeration
  [OrgExampleEnum]
  [OrgExampleEnumEmpty]
  [title=yes,
   text=Example,
   headalign=middle,
   alternative=top]")
  "The enumeration to wrap examples in.

Cons list of NAME, DEF. By default, shares a counter with
`org-context-enumerate-example-empty-environment' If nil,
examples are not wrapped in an enumeration"
  :group 'org-export-context
  :type '(cons (string :tag "Environment Name")
               (string :tag "Environment Definition")))

(defcustom org-context-enumerate-listing-empty-environment
  '("OrgListingEnumEmpty" . "\\defineenumeration
  [OrgListingEnumEmpty]
  [alternative=empty,
   margin=0pt]")
  "The enumeration for unlabelled listings.

Cons list of NAME, DEF. By default, shares a counter with
`org-context-enumerate-listing-environment'. If null, listings
are not enumerated."
  :group 'org-export-context
  :type '(cons (string :tag "Environment Name")
               (string :tag "Environment Definition")))

(defcustom org-context-enumerate-listing-environment
  '("OrgListingEnum" . "\\defineenumeration
  [OrgListingEnum]
  [OrgListingEnumEmpty]
  [title=yes,
   text=Listing,
   headalign=middle,
   alternative=top]")
  "The enumeration for listings.

Cons list of NAME, DEF. By default, shares a counter with
`org-context-enumerate-listing-empty-environment'. If null,
listings are not enumerated."
  :group 'org-export-context
  :type '(cons (string :tag "Environment Name")
               (string :tag "Environment Definition")))

(defcustom org-context-enumerate-verse-empty-environment
  '("OrgVerseEnumEmpty" . "\\defineenumeration
  [OrgVerseEnumEmpty]
  [alternative=empty,
   margin=0pt]")
  "The environment name that wraps verses to list them.

Cons list of NAME, DEF. If nil, verses aren't enumerated."
  :group 'org-export-context
  :type '(cons (string :tag "Environment Name")
               (string :tag "Environment Definition")))

(defcustom org-context-enumerate-verse-environment '("OrgVerseEnum" . "
\\defineenumeration
  [OrgVerseEnum]
  [OrgVerseEnumEmpty]
  [title=yes,
   text=Verse,
   alternative=top]")
  "The environment name that wraps verses to list them.

Cons list of NAME, DEF. If nil, verses aren't enumerated."
  :group 'org-export-context
  :type '(cons (string :tag "Environment Name")
               (string :tag "Environment Definition")))

;;;; ConTeXt commands

;; These commands provide names and implementations of Org elements
;; in ConTeXt.

(defcustom org-context-bullet-off-command
  '("OrgItemOff" . "\\define\\OrgItemOff{\\square}")
  "The name of the command that creates bullets for uncompleted items.

Cons list of NAME, DEF. If nil, the command isn't created.
Command should take no arguments."
  :group 'org-export-context
  :type '(cons (string :tag "Command Name")
               (string :tag "Command Definition")))

(defcustom org-context-bullet-on-command
  '("OrgItemOn" . "\\define\\OrgItemOn{\\boxplus}")
  "The name of the command that creates bullets for completed items.

Cons list of NAME, DEF. If nil, the command isn't created.
Command should take no arguments."
  :group 'org-export-context
  :type '(cons (string :tag "Command Name")
               (string :tag "Command Definition")))

(defcustom org-context-bullet-trans-command
  '("OrgItemTrans" . "\\define\\OrgItemTrans{\\boxtimes}")
  "The name of the command that creates bullets for partially completed items.

Cons list of NAME, DEF. If nil, the command isn't created.
Command should take no arguments."
  :group 'org-export-context
  :type '(cons (string :tag "Command Name")
               (string :tag "Command Definition")))

(defcustom org-context-clock-command
  '("OrgClock" . "\\def\\OrgClock#1[#2]{%
  \\getparameters
    [OrgClock]
    [y=,
     m=,
     d=,
     H=,
     M=,
     I=,
     S=,
     #2]
  \\doifnot{\\OrgClocky}{}{%
    \\date[year=\\OrgClocky,month=\\OrgClockm,day=\\OrgClockd]
          [year, --, mm, --, dd]}%
  \\doifnot{\\OrgClockH}{}{T\\OrgClockH:\\OrgClockM%
  \\doifnot{\\OrgClockS}{}{:\\OrgClockS}}
}")
  "The name of the command that formats clocks.

Cons list of NAME, DEF. If nil, the command isn't created.
Command should take the following keyword arguments:
  `y': The year
  `m': The month
  `d': The day
  `H': The hour on a 24 hour clock
  `I': The hour on a 12 hour clock
  `M': The minute
  `S': The second"
  :group 'org-export-context
  :type '(cons (string :tag "Command Name")
               (string :tag "Command Definition")))

(defcustom org-context-description-command
  '("OrgDesc" . "\\definedescription[OrgDesc]")
  "The command name to be used for Org description items.

Cons list of NAME, DEF. If nil, \"\\description\" is used.
Should define a description environment."
  :group 'org-export-context
  :type '(cons (string :tag "Command Name")
               (string :tag "Command Definition")))

(defcustom org-context-drawer-command
  '("OrgDrawer" . "\\define[2]\\OrgDrawer{#2}")
  "The name of the command that formats drawers.

Cons list of NAME, DEF. If nil, the command isn't created.
Command should take a single argument -- the contents of the
drawer."
  :group 'org-export-context
  :type '(cons string string))

(defcustom org-context-headline-command
  '("OrgHeadline" . "\\def\\OrgHeadline#1[#2]{%
  \\getparameters
    [OrgHeadline]
    [Todo=,
     TodoType=,
     Priority=,
     Text=,
     Tags=,
     #2]
  \\doifnot{\\OrgHeadlineTodo}{}{{\\sansbold{\\smallcaps{\\OrgHeadlineTodo}}\\space}}%
  \\doifnot{\\OrgHeadlinePriority}{}{{\\inframed{\\OrgHeadlinePriority}\\space}}%
  \\OrgHeadlineText%
  \\doifnot{\\OrgHeadlineTags}{}{{\\hfill\\tt\\OrgHeadlineTags}}%
}")
  "The name of the command that formats headlines.

Cons list of NAME, DEF. If nil, the command isn't created.
The command should take the following keyword arguments:

  `Todo': The todo keyword (if any) for the headline
  `TodoType': The type of the todo keyword for the headline
  `Priority': The headline's priority (if any)
  `Text': The text of the headline
  `Tags': The tags of the headline (as a colon-delimited list)"
  :group 'org-export-context
  :type '(cons (string :tag "Command Name")
               (string :tag "Command Definition")))

(defcustom org-context-inlinetask-command
  '("OrgInlineTask" . "\\def\\OrgInlineTask#1[#2]{%
  \\getparameters
    [OrgInlineTask]
    [Todo=,
     TodoType=,
     Priority=,
     Title=,
     Tags=,
     Contents=,
     #2]
  \\blank[big]
  \\startframedtext[align=normal, location=middle, width=0.6\\hsize]
  \\startalignment[middle]
  \\doifnot{\\OrgInlineTaskTodo}{}{\\sansbold{\\smallcaps{\\OrgInlineTaskTodo}} }%
  \\doifnot{\\OrgInlineTaskPriority}{}{\\inframed{\\OrgInlineTaskPriority} }%
  \\OrgInlineTaskTitle %
  \\doifnot{\\OrgInlineTaskTags}{}{{\\crlf\\tt\\OrgInlineTaskTags} }%
  \\crlf%
  \\textrule
  \\stopalignment
  \\OrgInlineTaskContents
  \\stopframedtext
  \\blank[big]
}")
  "The name of the command that formats inline tasks.

Cons list of NAME, DEF.The command should take the following
keyword arguments:
  `Todo': The todo keyword (if any) for the headline
  `TodoType': The type of the todo keyword for the headline
  `Priority': The headline's priority (if any)
  `Title': The title of the headline
  `Tags': The tags of the headline (as a colon-delimited list)
  `Contents': The contents of the inline tasks
If nil, returns a basic command with only the title and contents"
  :group 'org-export-context
  :type '(cons (string :tag "Command Name")
               (string :tag "Command Definition")))

(defcustom org-context-node-property-command
  '("OrgNodeProp" . "\\def\\OrgNodeProp#1[#2]{%
  \\getparameters
    [OrgNodeProp]
    [key=,
     value=,
     #2]%
{\\tt \\OrgNodePropkey: \\OrgNodePropvalue}\\crlf}")
  "The name of the command that formats nodes in drawers.

Cons list of NAME, DEF. Command should take the following keyword
arguments:

  `key': The node property key
  `value': The node property value"
  :group 'org-export-context
  :type '(cons (string :tag "Command Name")
               (string :tag "Command Definition")))

(defcustom org-context-planning-command
  '("OrgPlanning" . "\\def\\OrgPlanning#1[#2]{%
  \\getparameters
    [OrgPlanning]
    [ClosedString=,
     ClosedTime=,
     DeadlineString=,
     DeadlineTime=,
     ScheduledString=,
     ScheduledTime=,
     #2]
  \\doifnot{\\OrgPlanningClosedString}{}{\\OrgPlanningClosedString\\space}
  \\doifnot{\\OrgPlanningClosedTime}{}{\\OrgPlanningClosedTime\\space}
  \\doifnot{\\OrgPlanningDeadlineString}{}{\\OrgPlanningDeadlineString\\space}
  \\doifnot{\\OrgPlanningDeadlineTime}{}{\\OrgPlanningDeadlineTime\\space}
  \\doifnot{\\OrgPlanningScheduledString}{}{\\OrgPlanningScheduledString\\space}
  \\doifnot{\\OrgPlanningScheduledTime}{}{\\OrgPlanningScheduledTime\\space}
  \\crlf
}")
  "The name of the command that formats planning items.

Cons list of NAME, DEF. If nil, just returns a plain text time
stamp and label. The command should accept the following keyword
arguments:

  `ClosedString': The locally-defined CLOSED keyword
  `ClosedTime': The time the item was closed
  `DeadlineString': The locally-defined DEADLINE keyword
  `DeadlineTime': The time of the deadline
  `ScheduledString': The locally-defined SCHEDULED keyword
  `ScheduledTime': The time scheduled"
  :group 'org-export-context
  :type '(cons (string :tag "Command Name")
               (string :tag "Command Definition")))

(defcustom org-context-toc-title-command
  '("\\OrgTitleContents" . "\\define\\OrgTitleContents{{\\tfc Contents}}")
  "The command that titles the table of contents.

Cons list of NAME, DEF. "
  :group 'org-export-context
  :type '(cons (string :tag "Command Name")
               (string :tag "Command Definitions")))

;;;; Element Configuration

;; These settings configure elements in Org.


(defcustom org-context-export-quotes-alist
  '((primary-opening . "\\quotation{")
    (primary-closing . "}")
    (secondary-opening . "\\quote{")
    (secondary-closing . "}")
    (apostrophe . "'"))
  "Alist defining quote delimiters.
These define how different quotes are delimited in the output."
  :group 'org-export-context
  :type '(alist
          :key-type (symbol :tag "Type")
          :value-type (string :tag "Command")))

(defcustom org-context-preset "article"
  "The defalt preset to use when exporting.
See `org-context-presets-alist' for more information."
  :group 'org-export-context
  :type '(string :tag "ConTeXt preset"))

(defcustom org-context-float-default-placement "here"
  "Default placement for floats.

This is passed as the \"location\" key to the
\"\\startplacefigure\" command."
  :group 'org-export-context
  :type 'string
  :safe #'stringp)

(defcustom org-context-format-clock-function
  'org-context-format-clock-default-function
  "Function called to format a clock in ConTeXt code.

The function should take two parameters:

TIMESTAMP   the org timestamp
INFO        plist containing context information

The function should return the string to be exported."
  :group 'org-export-context
  :type 'function)

(defcustom org-context-format-drawer-function
  'org-context-format-drawer-default-function
  "Function called to format a drawer in ConTeXt code.

The function must accept two parameters:
  NAME      the drawer name, like \"LOGBOOK\"
  CONTENTS  the contents of the drawer.
  INFO      plist containing contextual information.

The function should return the string to be exported."
  :group 'org-export-context
  :type 'function)

(defcustom org-context-format-headline-function
  'org-context-format-headline-default-function
  "Function for formatting the headline's text.

This function will be called with six arguments:
TODO      the todo keyword (string or nil)
TODO-TYPE the type of todo (symbol: `todo', `done', nil)
PRIORITY  the priority of the headline (integer or nil)
TEXT      the main headline text (string)
TAGS      the tags (list of strings or nil)
INFO      the export options (plist)

The function result will be used in the section format string."
  :group 'org-export-latex
  :version "24.4"
  :package-version '(Org . "8.0")
  :type 'function)

(defcustom org-context-format-inlinetask-function
  'org-context-format-inlinetask-default-function
  "Function called to format an inlinetask in LaTeX code.

The function must accept seven parameters:
  TODO      the todo keyword (string or nil)
  TODO-TYPE the todo type (symbol: `todo', `done', nil)
  PRIORITY  the inlinetask priority (integer or nil)
  NAME      the inlinetask name (string)
  TAGS      the inlinetask tags (list of strings or nil)
  CONTENTS  the contents of the inlinetask (string or nil)
  INFO      the export options (plist)

The function should return the string to be exported."
  :group 'org-export-context
  :type 'function)

(defcustom org-context-format-timestamp-function
  'org-context-format-timestamp-default-function
  "Function called to format a timestamp in ConTeXt code.

The function should take one parameter, TIMESTAMP,
which is an Org timestamp object.

The function should return the string to be exported."
  :group 'org-export-context
  :type 'function)

(defcustom org-context-highlighted-langs-alist
  '(("metapost" . "mp")
    ("c++" . "cpp")
    ("c#" . "cs"))
  "Alist mapping languages to their counterpart in ConTeXt.
ConTeXt only supports a couple of languages out-of-the-box
so this is a short list."
  :group 'org-export-context
  :type '(alist
          :key-type (string :tag "Major mode")
          :value-type (string :tag "ConTeXt language")))

(defcustom org-context-image-default-height nil
  "Default height for images.

This is passed to the \"width\" key of the
\"\\placeexternalfigure\" command. Keys represent different
contexts (\"t\" being the default case). Values are the command
to use."
  :group 'org-export-context
  :type '(alist
          :key-type (choice
                     :tag "Context"
                     (const t)
                     (const wrap)
                     (const multicolumn)
                     (const sideways))
          :value-type (string :tag "Height command")))

(defcustom org-context-image-default-option ""
  "Default option for images."
  :group 'org-export-context
  :type 'string
  :safe #'stringp)

(defcustom org-context-image-default-scale nil
  "Default scale for images.

This is passed to the \"width\" key of the
\"\\placeexternalfigure\" command. Keys represent different
contexts (\"t\" being the default case). Values are the command
to use."
  :group 'org-export-context
  :type '(alist
          :key-type (choice
                     :tag "Context"
                     (const t)
                     (const wrap)
                     (const multicolumn)
                     (const sideways))
          :value-type (string :tag "Scale command")))

(defcustom org-context-image-default-width
  '((t . "\\dimexpr \\hsize - 1em \\relax")
    (sideways . "\\dimexpr \\hsize - 1em \\relax")
    (multicolumn . "\\dimexpr\\makeupwidth - 1em\\relax")
    (wrap . "0.48\\hsize"))
  "Default width for images.

This is passed to the \"width\" key of the
\"\\placeexternalfigure\" command. Keys represent different
contexts (\"t\" being the default case). Values are the command
to use."
  :group 'org-export-context
  :type '(alist
          :key-type (choice
                     :tag "Context"
                     (const t)
                     (const wrap)
                     (const multicolumn)
                     (const sideways))
          :value-type (string :tag "Width command")))

(defcustom org-context-inline-image-rules
  `(("file" . ,(rx "."
                   (or "pdf" "jpeg" "jpg" "png" "ps" "eps" "tikz" "pgf" "svg")
                   eos)))
  "Rules characterizing image files that can be inlined into ConTeXt.

A rule consists in an association whose key is the type of link
to consider, and value is a regexp that will be matched against
link's path."
  :group 'org-export-context
  :package-version '(Org . "9.4")
  :type '(alist :key-type (string :tag "Type")
                :value-type (regexp :tag "Path")))

(defcustom org-context-inner-templates-alist
  '(("empty" . "%t
%f
%c
%a
%i
%b
%o")
    ("article" . "\\startfrontmatter
\\startOrgTitlePage
\\OrgMakeTitle
%t
\\stopOrgTitlePage
%f
\\stopfrontmatter

\\startbodymatter
%c
\\stopbodymatter

\\startappendices
%a
%i
\\stopappendices

\\startbackmatter
%b
%o
\\stopbackmatter")
    ("report" . "\\startfrontmatter
\\startstandardmakeup
\\startOrgTitlePage
\\OrgMakeTitle
%t
\\stopOrgTitlePage
\\stopstandardmakeup
%f
\\stopfrontmatter

\\startbodymatter
%c
\\stopbodymatter

\\startappendices
%a
%i
\\stopappendices
\\startbackmatter
%b
%o
\\stopbackmatter"))
  "Alist of ConTeXt document body templates.
First element is the name of the template. Second element is
a format specification string.
String keys are as follows:

?f: Sections with the property :FRONTMATTER:
?c: Normal sections
?a: Sections with the property :APPENDIX:
?b: Sections with the property :BACKMATTER:
?o: Sections with the property :COPYING:
?i: Sections with the property :INDEX:"
  :group 'org-export-context
  :type '(alist
          :key-type (string :tag "Template Name")
          :value-type (string :tag "Template Contents")))


;; TODO test
(defcustom org-context-logfiles-extensions
  '("aux" "bcf" "blg" "fdb_latexmk" "fls" "figlist" "idx" "log" "nav" "out"
    "ptc" "run.xml" "snm" "toc" "vrb" "xdv" "tuc")
  "The list of file extensions to consider as ConTeXt logfiles.
The logfiles will be removed if `org-context-remove-logfiles' is
non-nil."
  :group 'org-export-context
  :type '(repeat (string :tag "Extension")))

(defcustom org-context-number-equations nil
  "Control numbering with \"$$ $$\" or \"\\[ \\]\" delimiters.

Non-nil means insert a \\placeformula
line before all formulas for numbering."
  :group 'org-export-context
  :type 'boolean)

;; TODO test
(defcustom org-context-pdf-process
  '("context %f")
  "Commands to process a ConTeXt file to a PDF file.

This is a list of strings, each of them will be given to the
shell as a command.  %f in the command will be replaced by the
relative file name, %F by the absolute file name, %b by the file
base name (i.e. without directory and extension parts), %o by the
base directory of the file, %O by the absolute file name of the
output file, %context is the ConTeXt compiler (see
`org-context-compiler').

Alternatively, this may be a Lisp function that does the
processing, so you could use this to apply the machinery of
AUCTeX or the Emacs LaTeX mode.  This function should accept the
file name as its single argument."
  :group 'org-export-pdf
  :type '(repeat (string :tag "Command")))

(defcustom org-context-presets-alist
  '(("empty" .
     (:literal ""
      :template "empty"
      :snippets ()))
    ("article" .
     (:literal "\\setupwhitespace[big]"
      :template "article"
      :snippets
      ("layout-article"
       "description-article"
       "quote-article"
       "verse-article"
       "table-article"
       "title-article"
       "sectioning-article"
       "page-numbering-article"
       "setup-grid")))
    ("report" .
     (:literal "\\setupwhitespace[big]"
      :template "report"
      :snippets
      ("description-article"
       "quote-article"
       "verse-article"
       "table-article"
       "title-report"
       "headlines-report"
       "page-numbering-article"
       "setup-grid"))))
  "Alist of ConTeXt preamble presets.

Presets are used to specify document structure, as well as
specifying the document preamble. The cdr of each item is a plist
with the following keys:
  `literal': Literal ConTeXt code to include in the preamble
  `template': A template specifying document structure
    (see `org-context-inner-templates-alist')
  `snippets': A list of snippets (as defined in
    `org-context-snippets-alist') to include in the preamble"
  :group 'org-export-context
  :type '(alist
          :key-type (string :tag "Preset Name")
          :value-type
          (list
           (const :tag "" :literal)
           (string :tag "Raw Inputs")
           (const :tag "" :template)
           (string :tag "Template name")
           (const :tag "" :snippets)
           (repeat (string :tag "Snippet Name")))))

;; TODO test
(defcustom org-context-remove-logfiles t
  "Non-nil means remove the logfiles produced by PDF production.
By default, logfiles are files with these extensions: .aux, .idx,
.log, .out, .toc, .nav, .snm and .vrb.  To define the set of
logfiles to remove, set `org-context-logfiles-extensions'."
  :group 'org-export-context
  :type 'boolean)

(defcustom org-context-snippets-alist
  '(
    ;; Syntax highlighting. Note that overriding pscolor overrides
    ;; the default so no further action is needed
    ("colors-pigmints" . "% Syntax highlighting that may superficially resemble Pygments
\\startcolorscheme[pscolor]
  \\definesyntaxgroup
    [Comment]
    [style=italic,color={x=408080}]
  \\definesyntaxgroup
    [Constant]
    [color={x=008000}]
  \\definesyntaxgroup
    [Error]
    [style=bold,color={x=D2413A}]
  \\definesyntaxgroup
     [Ignore]
  \\definesyntaxgroup
    [Identifier]
    []
  \\definesyntaxgroup
    [PreProc]
    [color={x=BC7A00}]
  \\definesyntaxgroup
    [Statement]
    [style=bold,color={x=AA22FF}]
  % Don't Know
  \\definesyntaxgroup
    [Special]
    [color={h=BA2121}]
  \\definesyntaxgroup
    [Todo]
    [color={h=800000},
      command=\\vimtodoframed]
  \\definesyntaxgroup
    [Type]
    [color={h=B00040}]
  \\definesyntaxgroup
    [Underlined]
    [color={h=6a5acd},
      command=\\underbar]
  \\setups{vim-minor-groups}
  \\definesyntaxgroup
    [StorageClass]
    [color={h=666666}]
  \\definesyntaxgroup
    [Number]
    [color={h=666666}]
  \\definesyntaxgroup
    [Operator]
    [color={h=666666}, style=bold]
  \\definesyntaxgroup
    [Keyword]
    [color={h=008000}, style=bold]
  \\definesyntaxgroup
    [Conditional]
    [Keyword]
  \\definesyntaxgroup
    [Repeat]
    [Keyword]
  \\definesyntaxgroup
    [Include]
    [Keyword]
  \\definesyntaxgroup
    [Label]
    [color={h=B00040}, style=bold]
  \\definesyntaxgroup
    [Function]
    [color={h=0000ff}]
  \\definesyntaxgroup
    [Macro]
    [Function]
  \\definesyntaxgroup
    [String]
    [color={x=BA2121}]
\\stopcolorscheme")
    ;; LaTeX-style descriptions
    ("description-article" . "\\setupdescription
  [OrgDesc]
  [headstyle=bold,
   style=normal,
   align=flushleft,
   alternative=hanging,
   width=broad,
   margin=1cm]")
    ;; Report title setuphead
    ;; LaTeX Report-style Headlines
    ("headlines-report" . "\\definehead[subsubsubsection][subsubsection]
\\definehead[subsubsection][subsection]
\\definehead[subsection][section]
\\definehead[section][chapter]
\\definehead[subsubsubsubsubject][subsubsubsubject]
\\definehead[subsubsubsubject][subsubsubject]
\\definehead[subsubsubject][subsubject]
\\definehead[subsubject][subject]
\\definehead[subject][title]
\\setuphead
  [subject,section]
  [before={\\startstandardmakeup[
        headerstate=normal, footerstate=normal, pagestate=start]},
    after={\\stopstandardmakeup}]")
    ;; Hanging indents on paragraphs
    ("indent-article" . "\\setupindenting[yes,medium,next]")
    ;; Margin setup for article style
    ("layout-article" . "\\setuplayout[
   backspace=103pt,
   topspace=92pt,
   header=12pt,
   headerdistance=25pt,
   width=middle,
   height=middle]")
    ;; Article page numbering
    ("page-numbering-article" . "\\setuppagenumbering[location={footer,middle}]")
    ;; US letter paper
    ("paper-letter" . "\\setuppapersize[letter]")
    ;; Indented quote blocks
    ("quote-article" . "\\defineblank[QuoteSkip][1ex]
\\setupstartstop
  [OrgBlockQuote]
  [style=slanted,
   before={\\blank[QuoteSkip]
      \\setupnarrower[left=1em, right=1em]
      \\startnarrower[left, right]
      \\noindent},
   after={\\stopnarrower
      \\blank[QuoteSkip]
      \\indenting[next]}]")
    ;; Title on same page as body
    ("sectioning-article" . "\\setupsectionblock[frontpart][page=no]
\\setupsectionblock[bodypart][page=no]")
    ;; LaTeX article style section numbering
    ("section-numbers-article" . "\\startsectionblockenvironment[frontpart]
\\setupheads[conversion=r]
\\stopsectionblockenvironment
\\startsectionblockenvironment[appendix]
\\setuphead[section][conversion=A]
\\setuphead[subsection][conversion=n, sectionsegments=subsection:*]
\\stopsectionblockenvironment
\\startsectionblockenvironment[backpart]
\\setupheads[number=no]
\\stopsectionblockenvironment
")
    ;; Grid typesetting (can cause issues with dense math)
    ("setup-grid" . "\\setuplayout[grid=both]
\\setupformulae[grid=both]")
    ;; LaTeX-style tables
    ("table-article" . "\\setupxtable
  [split=yes,
   header=repeat,
   footer=repeat,
   leftframe=off,
   rightframe=off,
   topframe=off,
   bottomframe=off,
   loffset=1em,
   roffset=1em,
   stretch=on]
\\setupxtable
  [OrgTableHeader]
  [toffset=1ex,
   foregroundstyle=bold,
   topframe=on,
   bottomframe=on]
\\setupxtable[OrgTableFooter][OrgTableHeader][]
\\setupxtable
  [OrgTableHeaderTop]
  [OrgTableHeader]
  [bottomframe=off]
\\setupxtable
  [OrgTableFooterTop]
  [OrgTableFooter]
  [bottomframe=off]
\\setupxtable
  [OrgTableHeaderBottom]
  [OrgTableHeader]
  [topframe=off]
\\setupxtable
  [OrgTableFooterBottom]
  [OrgTableFooter]
  [topframe=off]
\\setupxtable
  [OrgTableHeaderMid]
  [OrgTableHeader]
  [topframe=off,bottomframe=off]
\\setupxtable
  [OrgTableFooterMid]
  [OrgTableFooter]
  [topframe=off,bottomframe=off]
\\setupxtable
  [OrgTableTopRow]
  [topframe=on]
\\setupxtable
  [OrgTableRowGroupStart]
  [topframe=on]
\\setupxtable
  [OrgTableRowGroupEnd]
  [bottomframe=on]
\\setupxtable
  [OrgTableColGroupStart]
  [leftframe=on]
\\setupxtable
  [OrgTableColGroupEnd]
  [rightframe=on]
\\setupxtable
  [OrgTableBottomRow]
  [bottomframe=on]
")
    ;; LaTeX article style title setup
    ("title-article" . "\\setuphead[title][align=middle]
\\definestartstop[OrgTitlePage]
\\define\\OrgMakeTitle{%
  \\startalignment[center]
   \\blank[force,2*big]
   \\title{\\documentvariable{metadata:title}}
   \\doifnot{\\documentvariable{metadata:subtitle}}{}{
     \\blank[force,1*big]
     \\tfa \\documentvariable{metadata:subtitle}}
   \\doifelse{\\documentvariable{metadata:author}}{}{
   \\blank[3*medium]
   {\\tfa \\documentvariable{metadata:email}}
   }{
      \\blank[3*medium]
      {\\tfa \\documentvariable{metadata:author}}
   }
   \\blank[2*medium]
   {\\tfa \\documentvariable{metadata:date}}
   \\blank[3*medium]
  \\stopalignment}")
    ;; LaTeX report style title setup
    ("title-report" . "\\setuphead[title][align=middle]
\\definestartstop[OrgTitlePage]
\\define\\OrgMakeTitle{%
  \\startstandardmakeup[page=yes]
  \\startalignment[center]
   \\blank[force,2*big]
    \\title{\\documentvariable{metadata:title}}
   \\doifnot{\\documentvariable{metadata:subtitle}}{}{
     \\blank[force,1*big]
     \\tfa \\documentvariable{metadata:subtitle}}
   \\doifelse{\\documentvariable{metadata:author}}{}{
   \\blank[3*medium]
   {\\tfa \\documentvariable{metadata:email}}
   }{
      \\blank[3*medium]
      {\\tfa \\documentvariable{metadata:author}}
   }
   \\blank[2*medium]
   {\\tfa \\documentvariable{metadata:date}}
   \\blank[3*medium]
  \\stopalignment
  \\stopstandardmakeup}")
    ;; LaTeX style tables of contents
    ("toc-article" . "\\setupcombinedlist[content][alternative=c]")
    ;; Indented verse blocks with spaces preserved
    ("verse-article" . "\\defineblank[VerseSkip][1ex]
\\setuplines
  [OrgVerse]
  [before={\\blank[VerseSkip]
    \\setupnarrower[left=1em, right=1em]
    \\startnarrower[left, right]},
   after={\\stopnarrower \\blank[VerseSkip]},space=on]"))
  "Alist of snippet names and associated text.
These snippets will be inserted into the document preamble when
calling `org-context-make-template'. These snippets are also
available for use in presets. See also `org-context-presets-alist'"
  :group 'org-export-context
  :type `(alist
          :key-type (string :tag "Snippet Name")
          :value-type (string :tag "Snippet Value")))

(defcustom org-context-source-label "\\inright{%s}"
  "Command to use to format source block reference labels.
Should be a format string taking a single argument (the name of the label)"
  :group 'org-export-context
  :type 'string)

(defcustom org-context-syntax-engine
  'default
  "Option for the engine to use to perform syntax highlighting.
The `vim' option requires Vim to be installed."
  :tag "Default Syntax Engine"
  :group 'org-export-context
  :type '(choice (const :tag "Vim" vim)
                 (const :tag "Default" default)))

(defcustom org-context-table-location "force,here"
  "Default placement for table floats.

Contents are passed to the \"location\" key of the
\"\\startplacetable\" command when creating tables."
  :group 'org-export-context
  :type 'string)

(defcustom org-context-table-head "repeat"
  "If \"repeat\", repeat table headers across pages.

This string is passed to the \"header\" key of the
\"\\startxtable\" command."
  :group 'org-export-context
  :type 'string)

(defcustom org-context-table-foot ""
  "If \"repeat\", repeat table footers across pages.

This string is passed to the \"footer\" key of the
\"\\startxtable\" command."
  :group 'org-export-context
  :type 'string)

(defcustom org-context-table-option ""
  "Options to pass to the \"option\" keyword for \"\\startxtable\".

This string is passed to the \"option\" key of the
\"\\startxtable\" command."
  :group 'org-export-context
  :type 'string)

(defcustom org-context-table-style ""
  "A style string name to pass to use with the \"\\startxtable\" command."
  :group 'org-export-context
  :type 'string)

(defcustom org-context-table-float-style ""
  "A style string name to use with the \"\\startplacetable\" command."
  :group 'org-export-context
  :type 'string)

(defcustom org-context-table-split "yes"
  "If \"split\", tables default to split across pages.

This string is passed to the \"split\" key of the
\"\\startxtable\" command."
  :group 'org-export-context
  :type 'string)

(defcustom org-context-text-markup-alist
  '((bold ."\\bold{%s}")
    (bold-italic . "\\bolditalic{%s}")
    (code . protectedtexttt)
    (italic . "\\italic{%s}")
    (paragraph . "%s")
    (strike-through . "\\inframed[frame=off]{\\overstrike{%s}}")
    (subscript . "\\low{%s}")
    (superscript . "\\high{%s}")
    (underline . "\\underbar{%s}")
    (verbatim . protectedtexttt)
    (verb . "\\type{%s}"))
  "Alist of ConTeXt expressions to convert text markup."
  :group 'org-export-context
  :version "26.1"
  :package-version '(Org . "8.3")
  :type 'alist
  :options
  '(bold
    bold-italic
    code
    italic
    paragraph
    strike-through
    subscript
    superscript
    underline
    verbatim
    verb))

(defcustom org-context-toc-command-alist
  '(("tables" . "\\placelistoftables[criterium=all]")
    ("figures" . "\\placelistoffigures[criterium=all]")
    ("equations" . "\\placelist[formula][criterium=all]")
    ("references" . "\\placelistofpublications[criterium=all]")
    ("definitions" . "\\placeindex"))
  "Alist of KEYWORD, COMMAND pairs.

\"#+TOC: KEYWORD\" results in COMMAND being inserted at this
location. KEYWORD should be lower-case."
  :group 'org-export-context
  :type '(alist
          :key-type (string :tag "Keyword")
          :value-type (string :tag "Command")))

(defcustom org-context-texinfo-indices-alist
  '(("cp" . (:keyword "CINDEX" :command "OrgConcept"))
    ("fn" . (:keyword "FINDEX" :command "OrgFunction"))
    ("ky" . (:keyword "KINDEX" :command "OrgKeystroke"))
    ("pg" . (:keyword "PINDEX" :command "OrgProgram"))
    ("tp" . (:keyword "TINDEX" :command "OrgDataType"))
    ("vr" . (:keyword "VINDEX" :command "OrgVariable")))
  "Alist mapping Texinfo index abbreviations to plist of keywords and commands.
:keyword represents the corresponding TexInfo @index name. :command represents
the corresponding command name in ConTeXt."
  :group 'org-export-context
  :type '(alist :key-type string
                :value-type (list (const :tag "" :keyword)
                                  (string :tag "Keyword")
                                  (const :tag "" :command)
                                  (string :tag "Command"))))

(defcustom org-context-vim-langs-alist
  '(("c++" :vim-name "cpp" :context-name "Cpp")
    ("c#" :vim-name "cs" :context-name "CSharp")
    ("vba" :vim-name "basic" :context-name "VBA")
    ("bash" :vim-name "sh" :context-name "Bash")
    ("emacs-lisp" :vim-name "lisp" :context-name "ELisp"))
  "Alist mapping Org language names to their counterparts in Vim and ConTeXt.
Values not specified here will be automatically computed from the language name
in Org. Specify a value here if the name of the language in Org doesn't match
the name in Vim, or if the language name contains special characters that can't
be inserted into TeX."
  :group 'org-export-context
  :type '(repeat
          (list (string :tag "Org Language Name")
                (const :tag "" :doc "The name name of the language in Vim." :vim-name)
                (string :tag "Vim Name")
                (const :tag "" :doc "The name of the language to use in the document." :context-name)
                (string :tag "ConTeXt Name"))))


;;; Filters

(defun org-context-clean-invalid-line-breaks (data _backend _info)
  "Remove invalid line breaks from raw text.
DATA is the data to strip."
  (replace-regexp-in-string
   "\\(\\\\stop[A-Za-z0-9*]+\\|^\\)[ \t]*\\\\\\\\[ \t]*$"
   "\\1"
   data))

(defun org-context-math-block-options-filter (info _backend)
  "Filter math blocks prior to parsing.
INFO is a plist containing contextual information."
  (dolist (prop '(:author :date :title) info)
    (plist-put info prop
               (org-context--wrap-latex-math-block (plist-get info prop) info))))

(defun org-context-texinfo-tree-filter (tree _backend info)
  "Convert Texinfo @-commands in indices in TREE prior to parsing.
INFO is a plist containing contextual information."
  (org-context--escape-texinfo tree info))

(defun org-context-math-block-tree-filter (tree _backend info)
  "Wrap math blocks in TREE prior to parsing.
INFO is a plist containing contextual information."
  (org-context--wrap-latex-math-block tree info))

;;; Internal functions

(defun org-context--add-reference (element contents info)
  "Add a reference label to CONTENTS.
INFO is a plist containing contextual information.
ELEMENT is the entity to add a reference label to."
  (if (not (and (org-string-nw-p contents) (org-element-property :name element)))
      contents
    (concat (org-context--get-reference element info)
          contents)))

(defun org-context--caption/label-string (element info)
  "Return caption and label ConTeXt string for ELEMENT.

INFO is a plist holding contextual information.  If there's no
caption nor label, return the empty string.

For non-floats, see `org-context--add-reference'."
  (let* ((main (org-export-get-caption element)))
    (org-export-data main info)))

(defun org-context--enumerated-block
    (ent contents info env-kw wrap-kw wrap-empty-kw &optional inner-args)
  "Helper function to wrap blocks in the correct environent.
ENT is the entity to wrap. CONTENTS is the block contents. INFO
is a plist holding contextual information. ENV-KW is the keyword
identifying the environment to place the contents into (see
`options-alist'). WRAP-KW is the keyword identifying the wrapper
environment to enumerate the contents in (see `options-alist').
WRAP-EMPTY-KW is the keyword identifying the wrapper environment
to use if no caption is specified (used to keep numbering
synchronized; see `options-alist'). INNER-ARGS is an alist of
arguments to add to the inner environment."
  (let* ((caption
          (org-trim
           (org-export-data
            (or (org-export-get-caption ent t)
                (org-export-get-caption ent))
            info)))
         (enumerate-environment
          (org-string-nw-p
           (car
            (plist-get info (if (org-string-nw-p caption) wrap-kw wrap-empty-kw)))))
         (environment
          (org-string-nw-p
           (car
            (plist-get info env-kw))))
         (label (org-context--label ent info t))
         (args (org-context--format-arguments
                (list
                 (cons "title" caption)
                 (cons "reference" label)))))
    (concat
     (if enumerate-environment
         (format "\\start%s\n  [%s]" enumerate-environment args)
       (org-context--get-reference ent info))
     (format "\n\\start%s%s\n" environment
             (if inner-args (format "[%s]" inner-args) ""))
     contents
     (format "\n\\stop%s\n" environment)
     (when enumerate-environment
       (format "\n\\stop%s" enumerate-environment)))))

(defun org-context--escape-texinfo (tree info)
  "Convert Texinfo @-commands in indices in TREE prior to parsing.
INFO is a plist contianing contextual information."
  (org-element-map tree 'keyword
    (lambda (object)
      (let* ((value (org-element-property :value object))
             (norm-value
              (with-temp-buffer
                (insert (replace-regexp-in-string
                         "@\\(\\(?:\\(?:La\\)?TeX\\)\\|\\(?:ConTeXt\\)\\){}"
                         "\\1"
                         value))
                (goto-char (point-min))
                (while
                    (re-search-forward
                     (concat
                      "\\("
                      texinfo-part-of-para-regexp
                      "\\)"
                      "\\([^}]*\\)"
                      "\\(}\\)") nil t)
                  (replace-match "" nil nil nil 1)
                  (replace-match "" nil nil nil 4))
                (buffer-string))))
        (org-element-put-property
         object
         :value
         norm-value)))
    info nil '(keyword) t)
  tree)

(defun org-context--format-arguments (arguments &optional oneline)
  "Format ARGUMENTS into a ConTeXt argument string.
ARGUMENTS is an alist of string, string pairs. For instance,
given '((\"key1\" . \"val1\") (\"key2\" . \"val2\")) returns
\"[key1=val1, key2=val2] or similar. If ONELINE is not nil,
formats all the arguments on one line (can be helpful in
verbatim environments)."
  (mapconcat
   (lambda (kv)
     (let ((key (car kv))
           (val (cdr kv)))
       (format "%s={%s}" key val)))
   (seq-filter (lambda (s) (org-string-nw-p (cdr s))) arguments)
   (if oneline "," ",\n   ")))

(defun org-context--get-reference (element info)
  "Gets a label for ELEMENT.
INFO is the current export state, as
a plist."
  (let ((label (org-context--label element info t))
        (name (org-export-get-node-property :name element)))
    (if name
        (format "\\reference[%s]{%s}\n" label name)
      (format "\\reference[%s]{}\n" label))))

(defun org-context--get-vim-lang-info (src-block info)
  "Get a plist containing langauge information for vim higlighting.
INFO is a plist that acts as a communication channel. SRC-BLOCK
is the code block to get information for.

Language translation info is cached in the INFO plist so that
typing environments can be defined in the template."
  (let ((org-lang (org-element-property :language src-block)))
    (if (org-string-nw-p org-lang)
      (let* ((lang-cache
              (or (plist-get info :context-languages-used-cache)
                  (let ((hash (make-hash-table :test #'equal)))
                    (plist-put info :context-languages-used-cache hash)
                    hash))))
        (or (gethash org-lang lang-cache)
            (puthash org-lang
                     (let ((lang-info
                            (or
                             (cdr
                              (assoc org-lang
                                     (plist-get info :context-vim-langs-alist)))
                             (list
                              :vim-name (downcase org-lang)
                              :context-name (capitalize org-lang)))))
                       (list
                        :vim-lang
                        (plist-get lang-info :vim-name)
                        :context-inline-name
                        (concat
                         (or
                          (org-string-nw-p
                           (car
                            (plist-get info :context-inline-source-environment)))
                          "")
                         (plist-get lang-info :context-name))
                        :context-block-name
                        (concat
                         (or
                          (org-string-nw-p
                           (car
                            (plist-get info :context-block-source-environment)))
                          "")
                         (plist-get lang-info :context-name))))
                     lang-cache))))))

(defun org-context--get-builtin-lang-name (src-block info)
  "Gets the ConTeXt name of a language from its Org name.
SRC-BLOCK is the code block to get the name of. INFO is a plist
containing contextual information."
  (let* ((org-lang (org-element-property :language src-block)))
    (and
     org-lang
     (or (cdr (assoc org-lang
                      (plist-get info :context-highlighted-langs)))
         (downcase org-lang)))))

(defun org-context--label (datum info &optional force full)
  "Return an appropriate label for DATUM.
DATUM is an element or a `target' type object.  INFO is the
current export state, as a plist.

Return nil if element DATUM has no NAME or VALUE affiliated
keyword or no CUSTOM_ID property, unless FORCE is non-nil.  In
this case always return a unique label.

Eventually, if FULL is non-nil, wrap label within \"\\label{}\"."
  (let* ((type (org-element-type datum))
	 (user-label
	  (org-element-property
	   (cl-case type
	     ((headline inlinetask) :CUSTOM_ID)
	     (target :value)
	     (otherwise :name))
	   datum))
	 (label
	  (and (or user-label force)
	       (concat (pcase type
                   (`headline "sec:")
                   (`table "tab:")
                   (`latex-environment
                    (and (string-match-p
                          org-context-latex-math-environments-re
                          (org-element-property :value datum))
                         "eq:"))
                   (`latex-matrices "eq:")
                   (`paragraph
                    (and (org-element-property :caption datum)
                         "fig:"))
                   (_ nil))
                 (org-export-get-reference datum info)))))
    (cond ((not full) label)
          (label
           (format
            "\\pagereference[%s]%s"
            label
            (if (eq type 'target) "" "\n")))
          (t ""))))

(defun org-context--get-coderef-label (ref parent info)
  "Create a reference label for REF.
PARENT is the parent code block or example block referred to by REF.
See `org-context--find-coderef-parent' for finding that element.
INFO is a plist containing contextual information."
  (format "%s:%s" (org-context--label parent info t) ref))

(defun org-context--find-coderef-parent (ref info)
  "Resolve a code reference REF and return the element in which it appears.

INFO is a plist used as a communication channel.

This function is used in place of `org-export-resolve-coderef'
because ConTeXt provides semantics for line number references
already. Therefore, we just need a globally unique identifier for
the coderef."

  (or
   (org-element-map (plist-get info :parse-tree) '(example-block src-block)
     (lambda (el)
       (with-temp-buffer
         (insert (org-trim (org-element-property :value el)))
         (let* ((label-fmt (or (org-element-property :label-fmt el)
                               org-coderef-label-format))
                (ref-re (org-src-coderef-regexp label-fmt ref)))
           ;; Element containing ref is found. Always return ref.
           (when (re-search-backward ref-re nil t) el))))
     info 'first-match)
   (signal 'org-link-broken (list ref))))

(defun org-context--protect-url (text)
  "Protect special characters in string TEXT and return it."
  (replace-regexp-in-string
           "[%#\\]"
           (lambda (m)
             (pcase m
               ("\\" "\\letterbackslash ")
               ("#" "\\letterhash ")
               ("%" "\\letterpercent ")))
           text nil t))

(defun org-context--protect-text (text)
  "Protect special characters in string TEXT and return it."
  (replace-regexp-in-string
           "[|\\{}$%#~]"
           (lambda (m)
             (pcase (string-to-char m)
               (?\\ "\\\\backslash{}")
               (?~ "\\\\lettertilde{}")
               (?# "\\\\letterhash{}")
               (_ "\\\\\\&")))
           text nil nil))

(defun org-context--protect-texttt (text)
  "Protect special chars, then wrap TEXT in \"{\\tt }\"."
  ;; Can't get away with just relying on the \type macro to handle verbatim
  ;; text because it fails in certain contexts such as titles.
  (format "{\\tt %s}" (org-context--protect-text text)))

(defun org-context--text-markup (text markup info)
  "Format TEXT depending on MARKUP text markup.
INFO is a plist used as a communication channel. See
`org-context-text-markup-alist' for details"
  (let ((fmt (cdr (assq markup (plist-get info :context-text-markup-alist)))))
    (cl-case fmt
      ;; No format string: Return raw text.
      ((nil) text)
      (verb
       (format "\\type{%s}" text))
      (protectedtexttt (org-context--protect-texttt text))
      (t (format fmt text)))))

(defun org-context--wrap-env (ent contents info env-key &optional default)
  "Wraps content in an environment with a label.
ENT is the entity to wrap in an environment.
CONTENTS is the contents of the entity to wrap.
INFO is a plist containing contextual information.
ENV-KEY is a keyword from `:options-alist'.
DEFAULT is the default environment if the environment
in ENV-KEY is not implemented.
Environment is looked up from the info plist."
  (let* ((prog-env-name (car (plist-get info env-key)))
         (env-name (or (org-string-nw-p prog-env-name) default)))
    (org-context--add-reference
     ent
     (if env-name
         (format "\\start%s\n%s\n\\stop%s\n" env-name contents env-name)
       contents)
     info)))

(defun org-context--wrap-latex-math-block (data info)
  "Merge continuous math objects in a pseudo-object container.
DATA is a parse tree or a secondary string. INFO is a plist
containing export options. Modify DATA by side-effect and return it."
  (let ((valid-object-p
        ;; Non-nill when OBJECT can be added to a latex math block
        (lambda (object)
          (pcase (org-element-type object)
            (`entity (org-element-property :latex-math-p object))
            (`latex-fragment
             (let
                 ((value (org-element-property :value object)))
               (or (string-prefix-p "\\(" value)
                   (string-match-p "\\`\\$[^$]" value))))))))
    (org-element-map
        data
        '(entity latex-fragment)
      (lambda (object)
        (when
            (and
             (not
              (eq
               (org-element-type
                (org-element-property :parent object))
               'latex-math-block))
             (funcall valid-object-p object))
          (let
              ((math-block (list 'latex-math-block nil))
               (next-elements (org-export-get-next-element object info t))
               (last object))
            ;; Wrap MATH-BLOCK around OBJECT in DATA.
            (org-element-insert-before math-block object)
            (org-element-extract-element object)
            (org-element-adopt-elements math-block object)
            (when (zerop (or (org-element-property :post-blank object) 0))
              ;; MATH-BLOCK swallows consecutive math objects.
              (catch 'exit
                (dolist (next next-elements)
                  (unless (funcall valid-object-p next) (throw 'exit nil))
                  (org-element-extract-element next)
                  (org-element-adopt-elements math-block next)
                  ;; Eschew the case: \beta$x$ -> \(\betax\)
                  (org-element-put-property last :post-blank 1)
                  (setq last next)
                  (when (> (or (org-element-property :post-blank next) 0) 0)
                    (throw 'exit nil)))))
            (org-element-put-property
             math-block :post-blank (org-element-property :post-blank last)))))
      info nil '(latex-latex-math-block) t)
    data))

(defun org-context--strip-text (obj info)
  "Extract raw (unformatted) text from OBJ.
INFO is a plist providing contextual information."
  (let ((backend
         (org-export-create-backend
          :parent 'org
          :transcoders
          '((bold . (lambda (o c i) c))
            (code . (lambda (o c i) (org-element-property :value o)))
            (italic . (lambda (o c i) c))
            (strike-through . (lambda (o c i) c))
            (subscript . (lambda (o c i) c))
            (superscript . (lambda (o c i) c))
            (underline . (lambda (o c i) c))
            (verbatim . (lambda (o c i) (org-element-property :value o)))
            (underline . (lambda (o c i) c))
            (target . (lambda (o c i) ""))))))
    (org-export-data-with-backend obj backend info)))

;;; Transcode Functions

;;;; Bold

(defun org-context-bold (bold contents info)
  "Transcode BOLD from Org to ConTeXt.
CONTENTS is the text with bold markup. INFO is a plist holding
contextual information."
  (let ((italicp (org-element-lineage bold '(italic))))
    (if italicp
        (org-context--text-markup contents 'bold-italic info)
      (org-context--text-markup contents 'bold info))))

;;;; Center Block

(defun org-context-center-block (center-block contents info)
  "Transcode a CENTER-BLOCK element from Org to ConTeXt.
CONTENTS holds the contents of the center block.  INFO is a plist
holding contextual information."
  (org-context--add-reference
   center-block (format "\\startalignment[middle]\n%s\\stopalignment" contents) info))

;;;; Clock

(defun org-context-format-clock-default-function (timestamp info)
  "Format a timestamp in ConTeXt format.
TIMESTAMP is an Org timestamp. INFO is a plist containing
contextual information."
  (let* ((time (org-timestamp-to-time timestamp))
         (args
          (list
           (cons "y" (format-time-string "%Y" time))
           (cons "m" (format-time-string "%m" time))
           (cons "d" (format-time-string "%d" time))
           (cons "H" (format-time-string "%H" time))
           (cons "M" (format-time-string "%M" time))
           (cons "I" (format-time-string "%I" time))
           (cons "S" (format-time-string "%S" time))))
         (formatter
          (org-string-nw-p
           (car (plist-get info :context-clock-command)))))
    (if formatter
        (format "\\%s[%s]" formatter (org-context--format-arguments args))
      (format-time-string "%FT%T%z" time))))

(defun org-context-clock (clock _contents info)
  "Transcode a CLOCK element from Org to ConTeXt.
CONTENTS is nil.  INFO is a plist holding contextual
information."
  (let ((timestamp (org-element-property :value clock))
        (formatter (plist-get info :context-format-clock-function)))
    (funcall formatter timestamp info)))

;;;; Code

(defun org-context-code (code _contents info)
  "Transcode CODE from Org to ConTeXt.
INFO is a plist containing contextual information."
  (org-context--text-markup (org-element-property :value code) 'code info))

;;;; Drawer

(defun org-context-drawer (drawer contents info)
  "Transcode a DRAWER element from Org to ConTeXt.
CONTENTS holds the contents of the block.  INFO is a plist
holding contextual information."
  (let* ((name (org-element-property :drawer-name drawer))
         (output (funcall (plist-get info :context-format-drawer-function)
                          name contents info)))
    (org-context--add-reference drawer output info)))

(defun org-context-format-drawer-default-function (name contents info)
  "Format a drawer using the default.
NAME is the name of the drawer. CONTENTS is the contents of the drawer.
INFO is a plist containing contextual information."
  (let ((formatter
         (org-string-nw-p
          (car (plist-get info :context-drawer-command)))))
    (if formatter
        (format "\\%s{%s}{%s}" formatter name contents)
      (format "%s\\hairline %s" name contents))))

;;;; Dynamic Block

(defun org-context-dynamic-block (dynamic-block contents info)
  "Transcode a DYNAMIC-BLOCK element from Org to LaTeX.
CONTENTS holds the contents of the block.  INFO is a plist
holding contextual information.  See `org-export-data'."
  (org-context--add-reference dynamic-block contents info))

;;;; Entity

(defun org-context-entity (entity _contents _info)
  "Transcode an ENTITY object from Org to ConTeXt.
CONTENTS are the definition itself. INFO is a plist
holding contextual information."
  ;; Just use the utf-8 version because ConTeXt supports utf-8.
  ;; Can't guarantee codes for LaTeX will match.
  (org-element-property :utf-8 entity))

;;;; Example Block

(defun org-context-example-block (example-block _contents info)
  "Transcode an EXAMPLE-BLOCK element from Org to ConTeXt.
CONTENTS is nil. INFO is a plist holding contextual information."
  (let* ((contents (org-context--preprocess-source-block example-block info))
         (num-start (org-export-get-loc example-block info))
         (num-start-str
          (when (and num-start (> num-start 0))
            (number-to-string (+ 1 num-start))))
         (args
          (org-string-nw-p
           (org-context--format-arguments
            (list
             (cons "start" num-start-str)
             (cons "numbering" (when num-start "line")))))))
    (when contents
      (org-context--enumerated-block
       example-block
       (org-context--preprocess-source-block example-block info)
       info
       :context-example-environment
       :context-enumerate-example-environment
       :context-enumerate-example-empty-environment
       args))))

;;;; Export Block

(defun org-context-export-block (export-block _contents _info)
  "Transcode a EXPORT-BLOCK element from Org to ConTeXt.
CONTENTS is nil. INFO is a plist holding contextual information."
  (let ((type (org-element-property :type export-block))
        (value (org-element-property :value export-block)))
    (cond ((member type '("CONTEXT" "TEX"))
           (org-remove-indentation value))
          ((member type '("METAPOST"))
           (format "\\startMPcode\n%s\\stopMPcode"
                   (org-remove-indentation value))))))

;;;; Export Snippet

(defun org-context-export-snippet (export-snippet _contents _info)
  "Transcode an EXPORT-SNIPPET object from Org to ConTeXt.
CONTENTS is nil. INFO is a plist holding contextual information."
  (when (eq (org-export-snippet-backend export-snippet) 'context)
    (org-element-property :value export-snippet)))

;;;; Fixed Width

(defun org-context-fixed-width (fixed-width _contents info)
  "Transcode a FIXED-WIDTH element from Org to LaTeX.
CONTENTS is nil. INFO is a plist holding contextual information."
  (org-context--wrap-env
   fixed-width
   (org-remove-indentation (org-element-property :value fixed-width))
   info
   :context-fixed-environment
   "typing"))

;;;; Footnote Reference

(defun org-context-footnote-reference (footnote-reference _contents info)
  "Transcode a FOOTNOTE-REFERENCE element from Org to ConTeXt.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (let* ((footnote-definition
          (org-export-get-footnote-definition footnote-reference info))
         (reference-label (org-context--label footnote-definition info t))
         (contents (org-trim (org-export-data footnote-definition info)))
         (insidep (org-element-lineage footnote-reference
                                       '(footnote-reference
                                         footnote-definition
                                         table-cell))))
    (concat
     (format "\\note[%s]" reference-label)
     (when (not insidep)
       (concat "\n"
               (format "\\footnotetext[%s]{%s}%%\n" reference-label contents)
               (org-context--delayed-footnotes-definitions footnote-definition info))))))

(defun org-context--delayed-footnotes-definitions (element info)
  "Return footnotes definitions in ELEMENT as a string.

INFO is a plist used as a communication channel.

Footnotes definitions are returned within \"\\footnotetext{}\"
commands. This is done to make the handling of footnotes more
uniform."
  (mapconcat
   (lambda (ref)
     (let ((def (org-export-get-footnote-definition ref info)))
       (format "\\footnotetext[%s]{%s}%%\n"
	       (org-trim (org-context--label def info t))
	       (org-trim (org-export-data def info)))))
   ;; Find every footnote reference in ELEMENT.
   (letrec ((all-refs nil)
            (search-refs
             (lambda (data)
               ;; Return a list of all footnote references never seen
               ;; before in DATA.
               (org-element-map data 'footnote-reference
                 (lambda (ref)
                   (when (org-export-footnote-first-reference-p ref info)
                     (push ref all-refs)
                     (when (eq (org-element-property :type ref) 'standard)
                       (funcall search-refs
                                (org-export-get-footnote-definition ref info)))))
                 info)
               (reverse all-refs))))
     (funcall search-refs element))
   ""))

;;;; Headline

(defun org-context-headline (headline contents info)
  "Transcode a HEADLINE element from Org to ConTeXt.
CONTENTS is the content of the section. INFO is a plist
containing contextual information."
  (unless (org-element-property :footnote-section-p headline)
    (let* ((level (org-export-get-relative-level headline info))
           (text (org-export-data (org-element-property :title headline) info))
           (alt-title
            (org-trim
             (or (org-export-get-node-property :ALT_TITLE headline)
                (replace-regexp-in-string "[$|%#\\]" ""
                 (org-context--strip-text
                  (org-element-property :title headline)
                  info)))))
           (todo
            (and (plist-get info :with-todo-keywords)
                 (let ((todo (org-element-property :todo-keyword headline)))
                   (and todo (org-export-data todo info)))))
           (todo-type (and todo (org-element-property :todo-type headline)))
           (tags (and (plist-get info :with-tags)
                      (org-export-get-tags headline info)))
           (priority-num (org-element-property :priority headline))
           (priority (and (plist-get info :with-priority)
                          priority-num
                          (string priority-num)))
           (full-text (funcall (plist-get info :context-format-headline-function)
                               todo todo-type priority text tags info))
           (headertemplate "\n\\startsectionlevel")
           (footercommand "\n\\stopsectionlevel")
           (headline-label (org-context--label headline info t ))
           (index (let ((i (org-export-get-node-property :INDEX headline t)))
                    (assoc i (plist-get info :context-texinfo-indices))))
           (copyingp (org-not-nil (org-export-get-node-property :COPYING headline t)))
           (frontmatterp
            (org-export-get-node-property :FRONTMATTER headline))
           (backmatterp
            (org-export-get-node-property :BACKMATTER headline))
           (appendixp
            (org-export-get-node-property :APPENDIX headline))
           (headline-args
            (org-context--format-arguments
             (list
              (cons "title" full-text)
              (cons "list" alt-title)
              (cons "marking" alt-title)
              (cons "bookmark" alt-title)
              (cons "reference" headline-label))))
           (result (concat
                    headertemplate
                    (format "[%s]" headline-args)
                    (and index
                         (format "\n\\placeregister[%s]"
                                 (plist-get (cdr index) :command)))
                    "\n\n"
                    contents
                    footercommand)))
      ;; Special sections are stuck in the plist somewhere else
      ;; for later rendering
      (cond
       (copyingp
        (let ((copying-sections
               (plist-get info :context-copying-sections)))
          (plist-put info :context-copying-sections
                     (cons result copying-sections))
          nil))
       (backmatterp
        (let ((backmatter-sections
               (plist-get info :context-backmatter-sections)))
          (plist-put info :context-backmatter-sections
                     (cons result backmatter-sections))
          nil))
       (frontmatterp
        (let ((frontmatter-sections
               (plist-get info :context-frontmatter-sections)))
          (plist-put info :context-frontmatter-sections
                     (cons result frontmatter-sections))
          nil))
       (appendixp
        (let ((appendix-sections
               (plist-get info :context-appendix-sections)))
          (plist-put info :context-appendix-sections
                     (cons result appendix-sections))
          nil))
       (index
        (let ((index-sections
               (plist-get info :context-index-sections)))
          (plist-put info :context-index-sections
                     (cons result index-sections))
          nil))
       (t result)))))

(defun org-context-format-headline-default-function
    (todo todo-type priority text tags info)
  "Default format function for a headline.
TODO is the actual text of the TODO keyword.
TODO-TYPE is the type of the todo.
PRIORITY is the priority of the item.
TEXT is the text of the headline.
TAGS is a list of tags associated with the headline.
INFO is a plist containing contextual information.
See `org-context-format-headline-function' for details."
  (let ((formatter (org-string-nw-p (car (plist-get info :context-headline-command)))))
    (if formatter
        (format
         "\\%s
   [%s]"
         formatter
         (org-context--format-arguments
          (list
           (cons "Todo" todo)
           (cons "TodoType" todo-type)
           (cons "Priority" priority)
           (cons "Text" text)
           (cons "Tags" (mapconcat #'org-context--protect-text tags ":")))))
      text)))

(defun org-context--get-all-headline-commands (pred info)
  "Scan the parse tree for all headlines used and return a list.
INFO is a plist containing contextual information. PRED is a
predicate function to exclude headlines that takes the headline
and INFO as arguments."
  (let ((tree (plist-get info :parse-tree)))
    (delq
     nil
     (delete-dups
      (mapcar
       (lambda (headline)
         (org-context--get-headline-command headline info))
       (seq-filter
        (lambda (headline)
          (funcall pred headline info))
        (org-element-map tree 'headline #'identity)))))))

(defun org-context--get-headline-command (headline info)
  "Create a headline name with the correct depth.
HEADLINE is the headline object. INFO is a plist containing
contextual information."
  (let* ((level (org-export-get-relative-level headline info))
         (numberedp (org-export-numbered-headline-p headline info))
         (prefix (apply 'concat (make-list (+ level (- 1)) "sub")))
         (suffix (if numberedp "section" "subject"))
         (hname (concat prefix suffix))
         (notoc (org-export-excluded-from-toc-p headline info)))
    (if notoc
        (format "%sNoToc" hname)
      hname)))

;;;; Horizontal Rule

(defun org-context-horizontal-rule (horizontal-rule _contents info)
  "Transcode a HORIZONTAL-RULE object from Org to ConTeXt.
CONTENTS is nil. INFO is a plist holding contextual information."
  (let ((prev (org-export-get-previous-element horizontal-rule info)))
    (concat
     ;; Make sure the rule doesn't start at the end of the current
     ;; line
     (when (and prev
                (let ((prev-blank (org-element-property :post-blank prev)))
                  (or (not prev-blank) (zerop prev-blank))))
       "\n")
     (org-context--add-reference
      horizontal-rule
      "\\textrule"
      info))))

;;;; Inline Src Block

(defun org-context-inline-src-block (inline-src-block _contents info)
  "Transcode an INLINE-SRC-BLOCK element from Org to ConTeXt.
CONTENTS holds the contents of the item. INFO is a plist holding
contextual information."
  (let ((engine (plist-get info :context-syntax-engine))
        (code (org-export-format-code-default inline-src-block info)))
    (pcase engine
      ('vim (org-context--highlight-inline-src-vim
             inline-src-block code info))
      (_ (org-context--highlight-inline-src-builtin
          inline-src-block code info)))))

(defun org-context--highlight-inline-src-builtin (src-block code info)
  "Wraps a source block in the builtin environment for ConTeXt source code.
Use this if you don't have Vim.

SRC-BLOCK is the code object to transcode.
CODE is the preprocessed contents of the code block.
INFO is a plist holding contextual information."
  (when code
    (let* ((lang (org-context--get-builtin-lang-name src-block info))
           (env-name
            (or
             (org-string-nw-p
              (car (plist-get info :context-inline-source-environment)))
             "type")))
      (format "\\%s%s{%s}"
              env-name
              (if (org-string-nw-p lang)
                  (format "[option=%s]" lang)
                "")
              code))))

(defun org-context--highlight-inline-src-vim (src-block code info)
  "Wraps a source block in a vimtyping environment.
This requires you have Vim installed and the t-vim module for
ConTeXt. SRC-BLOCK is the entity to wrap. CODE is the contents of
the entity. INFO is a plist containing contextual information."
  (let ((org-lang (org-element-property :language src-block)))
    (if (org-string-nw-p org-lang)
      (let* ((lang-info (org-context--get-vim-lang-info src-block info))
             (context-name (plist-get lang-info :context-inline-name)))
        (format "\\inline%s{%s}" context-name code)))))

;;;; Inlinetask

(defun org-context-inlinetask (inlinetask contents info)
  "Transcode an INLINETASK element from Org to ConTeXt.
CONTENTS holds the contents of the block. INFO is a plist
holding contextual information."
  (let* ((title (org-export-data (org-element-property :title inlinetask) info))
         (todo (and (plist-get info :with-todo-keywords)
                    (let ((todo (org-element-property :todo-keyword inlinetask)))
                      (and todo (org-export-data todo info)))))
         (todo-type (format "%s" (org-element-property :todo-type inlinetask)))
         (tags (and (plist-get info :with-tags)
                    (org-export-get-tags inlinetask info)))
         (priority-num (org-element-property :priority inlinetask))
         (priority (and (plist-get info :with-priority)
                        priority-num
                        (make-string 1 priority-num)))
         (format-func (plist-get info :context-format-inlinetask-function)))
    (funcall format-func
             todo todo-type priority title tags contents info)))

(defun org-context-format-inlinetask-default-function
    (todo todo-type priority title tags contents info)
  "Default format function for inlinetasks.
TODO is the actual text of the TODO keyword.
TODO-TYPE is the type of the todo.
PRIORITY is the priority of the item.
TITLE is the text of the headline.
TAGS is a list of tags associated with the headline.
CONTENTS is the contents of the task.
INFO is a plist containing contextual information.
See `org-context-format-inlinetask-function' for details."

  (let ((format-command
         (org-string-nw-p (car (plist-get info :context-inlinetask-command)))))
    (if format-command
        (format
         "\\%s
  [%s]"
         format-command
         (org-context--format-arguments
          (list
           (cons "Todo" todo)
           (cons "TodoType" todo-type)
           (cons "Priority" priority)
           (cons "Title" title)
           (cons "Tags" (org-make-tag-string (mapcar #'org-context--protect-text tags)))
           (cons "Contents" contents))))
      (concat title "\\hairline" contents "\\hairline"))))

;;;; Inner Template

(defun org-context-inner-template (contents info)
  "Return body of document string after ConTeXt conversion.
CONTENTS is the transcoded contents string. INFO is a plist
containing contextual information."
  (let* ((templates (plist-get info :context-inner-templates))
         (template-name
          (plist-get
           (cdr
            (assoc
             (plist-get info :context-preset)
             (plist-get info :context-presets)))
           :template))
         (template (cdr (assoc template-name templates)))
         (copying-sections
          (mapconcat
           'identity
           (reverse (plist-get info :context-copying-sections))
           "\n\n"))
         (frontmatter-sections
          (mapconcat
           'identity
           (reverse (plist-get info :context-frontmatter-sections))
           "\n\n"))
         (backmatter-sections
          (mapconcat
           'identity
           (reverse (plist-get info :context-backmatter-sections))
           "\n\n"))
         (appendix-sections
          (mapconcat
           'identity
           (reverse (plist-get info :context-appendix-sections))
           "\n\n"))
         (index-sections
          (mapconcat
           'identity
           (reverse (plist-get info :context-index-sections))
           "\n\n"))
         (toc-command
          (let* ((with-toc (plist-get info :with-toc))
                 (commands (org-context--get-all-headline-commands
                            (lambda (hl inf)
                              (and (not (org-export-excluded-from-toc-p hl inf))
                                   (if (wholenump with-toc)
                                        (<= (org-export-get-relative-level hl inf) with-toc)
                                     t)))
                            info))
                 (toc-title (car (plist-get info :context-toc-title-command))))
            (if (and with-toc commands)
                (format "%s
\\placecontent"
                        toc-title)
              ""))))
    (format-spec
     template
     (list (cons ?f frontmatter-sections)
           (cons ?c contents)
           (cons ?a appendix-sections)
           (cons ?b backmatter-sections)
           (cons ?o copying-sections)
           (cons ?i index-sections)
           (cons ?t toc-command)))))

;;;; Italic

(defun org-context-italic (italic contents info)
  "Transcode CONTENTS from Org to ConTeXt.
INFO is a plist containing contextual information."
  (let ((boldp (org-element-lineage italic '(bold))))
    (if boldp
        (org-context--text-markup contents 'bold-italic info)
      (org-context--text-markup contents 'italic info))))

;;;; Item

(defun org-context-item (item contents info)
  "Transcode an ITEM element from Org to ConTeXt.
CONTENTS is the contents of the item. INFO is a plist containing
contextual information."
  (let ((tag (let ((tag (org-element-property :tag item)))
               (and tag (org-export-data tag info))))
        (checkbox (cl-case (org-element-property :checkbox item)
                    (on (format "\\%s" (car (plist-get info :context-bullet-on-command))))
                    (off (format "\\%s" (car (plist-get info :context-bullet-off-command))))
                    (trans (format "\\%s" (car (plist-get info :context-bullet-trans-command)))))))
    (if (eq (org-element-property :type (org-export-get-parent item))
            'descriptive)
        (let ((descrcommand (car (plist-get info :context-description-command))))
          (format "\\start%s{%s}\n%s\n\\stop%s"
                  descrcommand
                  (if (org-string-nw-p checkbox)
                      (format "%s\\space\\space %s" checkbox tag)
                    tag)
                  (org-trim (or contents ""))
                  descrcommand))
      (if (org-string-nw-p checkbox)
          (format "\\sym{%s} %s" checkbox contents)
        (format "\\item %s" (org-trim (or contents "")))))))

;;;; Keyword

(defun org-context-keyword (keyword _contents info)
  "Transcode a KEYWORD element from Org to ConTeXt.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (let ((key (org-element-property :key keyword))
        (value (org-element-property :value keyword))
        (special-indices
         (cl-map
          'identity
          (lambda (elem) (plist-get (cdr elem) :keyword))
          (plist-get info :context-texinfo-indices))))
    (format
     "\n%s\n"
     (pcase key
       ("CONTEXT" value)
       ("INDEX" (format "\\index{%s}" (org-context--protect-text value)))
       ("TOC"
        (let ((case-fold-search t)
              (texinfo-command (assoc value (plist-get info :context-texinfo-indices)))
              (toc-command (assoc value (plist-get info :context-toc-command-alist)))
              kw)
          (cond
           (toc-command (cdr toc-command))
           (texinfo-command
            (format "\\placeregister[%s]"
                    (plist-get (cdr texinfo-command) :command)))
           ((string-match-p "\\<headlines\\>" value)
            (let* ((localp (string-match-p "\\<local\\>" value))
                   (parent (org-element-lineage keyword '(headline)))
                   (depth
                    (if (string-match "\\<[0-9]+\\>" value)
                        (string-to-number (match-string 0 value))
                      0))
                   (level (+ depth
                             (if (not (and localp parent)) 0
                               (org-export-get-relative-level parent info))))
                   (levelstring
                    (if (> level 0)
                        (format
                         "list={%s}"
                         (mapconcat
                          'identity
                          (org-context--get-all-headline-commands
                           (lambda (hl inf)
                             (and
                              (<= (org-export-get-relative-level hl inf) level)
                              (not (org-export-excluded-from-toc-p hl inf))))
                           info)
                          ","))
                      "")))
              (if localp (format  "\\placecontent[criterium=local,%s]" levelstring)
                (format  "\\placecontent[%s]" levelstring))))
           ((or
             (and (string-match-p "\\<listings\\>" value)
                  (setq kw :context-enumerate-listing-empty-environment))
             (and (string-match-p "\\<verses\\>" value)
                  (setq kw :context-enumerate-verse-empty-environment))
             (and (string-match-p "\\<quotes\\>" value)
                  (setq kw :context-enumerate-blockquote-empty-environment))
             (and (string-match-p "\\<examples\\>" value)
                  (setq kw :context-enumerate-example-empty-environment)))
            (let ((env
                   (org-string-nw-p
                    (car
                     (plist-get info kw)))))
              (if env (format "\\placelist[%s][criterium=all]" env)
                "")))
           (t ""))))
       ((pred (lambda (x) (member x special-indices)))
        (format "\\%s{%s}\n"
                (plist-get
                 (cdr
                  (car
                   (seq-filter
                    (lambda (elem)
                      (string= key (plist-get (cdr elem) :keyword)))
                    (plist-get info :context-texinfo-indices))))
                 :command)
                (org-context--protect-text value)))
       (_ "")))))

(defun org-context--get-bib-file (keyword)
  "Return bibliography file as a string.
KEYWORD is a \"BIBLIOGRAPHY\" keyword. If no file is found,
return nil instead."
  (let ((value (org-element-property :value keyword)))
    (and value
         (string-match "\\(\\S-+\\)[ \t]+\\(\\S-+\\)\\(.*\\)" value)
         (concat (match-string 1 value) ".bib"))))

;;;; Latex Enviroment

(defun org-context-latex-environment (latex-environment _contents info)
  "Transcode a LATEX-ENVIRONMENT element from Org to ConTeXt.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (when (plist-get info :with-latex)
    (let* ((value (org-remove-indentation
                   (org-element-property :value latex-environment)))
           (environment-name
            (org-context--latex-environment-name latex-environment))
           (environment-contents
            (org-context--latex-environment-contents
             latex-environment))
           (numberedp
            (not (string-match "\\*$" environment-name)))
           (type (org-context--environment-type latex-environment))
           (label (org-context--label latex-environment info t))
           (args (org-context--format-arguments
                  (list
                   (cons "reference" label)))))
      (pcase type
        ('math
         (concat
          (when numberedp
            (format "\\startplaceformula\n  [%s]\n" args))
          "\\startformula\n"
          (pcase environment-name
            ((or "align" "align*")
             (org-context--transcode-align environment-contents))
            (_ environment-contents))
          "\\stopformula"
          (when numberedp "\\stopplaceformula")))
        (_ value)))))

(defun org-context--environment-type (latex-environment)
  "Return the TYPE of LATEX-ENVIRONMENT.

The TYPE is determined from the actual latex environment."
  (let* ((latex-begin-re "\\\\begin{\\([A-Za-z0-9*]+\\)}")
         (value (org-remove-indentation
                 (org-element-property :value latex-environment)))
         (env (or (and (string-match latex-begin-re value)
                       (match-string 1 value))
                  "")))
    (cond
     ((string-match-p org-context-latex-math-environments-re value) 'math)
     ((string-match-p
       (eval-when-compile
         (regexp-opt '("table" "longtable" "tabular" "tabu" "longtabu")))
       env)
      'table)
     ((string-match-p "figure" env) 'image)
     ((string-match-p
       (eval-when-compile
         (regexp-opt '("lstlisting" "listing" "verbatim" "minted")))
       env)
      'src-block)
     (t 'special-block))))

(defun org-context--latex-environment-contents (latex-environment)
  "Return the contents of LATEX-ENVIRONMENT."
  (let* ((latex-env-re "\\\\begin{\\([A-Za-z0-9*]+\\)}\\(\\(?:.*\n\\)*\\)\\\\end{\\1}")
         (value (org-remove-indentation
                 (org-element-property :value latex-environment)))
         (env-contents (progn (string-match latex-env-re value)
                              (match-string 2 value))))
    env-contents))

(defun org-context--latex-environment-name (latex-environment)
  "Return the NAME of LATEX-ENVIRONMENT.

The TYPE is determined from the actual latex environment."
  (let* ((latex-begin-re "\\\\begin{\\([A-Za-z0-9*]+\\)}")
         (value (org-remove-indentation
                 (org-element-property :value latex-environment)))
         (env (or (and (string-match latex-begin-re value)
                       (match-string 1 value))
                  "")))
    env))

(defun org-context--transcode-align (align-environment)
  "Transcode an ALIGN-ENVIRONMENT from org to ConTeXt."
  (let ((len (length (split-string align-environment "\\\\\\\\"))))
    (if (= len 1)
        (org-trim align-environment)
      (concat
   "\\startalign\n"
   (mapconcat
   (lambda (math-row)
     (concat
      "\\NC "
      ;; Strip surrounding whitespace
      (replace-regexp-in-string
       "\\`[ \t\n]*"
       ""
       (replace-regexp-in-string
        "[ \t\n]*\\'"
        ""
        (replace-regexp-in-string "[^\\]&" " \\\\NC " math-row)))))
   (seq-filter 'org-string-nw-p
               (split-string align-environment "\\\\\\\\"))
   " \\NR[+]\n")
   " \\NR[+]\n\\stopalign\n"))))

;;;; Latex Fragment

(defun org-context-latex-fragment (latex-fragment _contents info)
  "Transcode a LATEX-FRAGMENT object from Org to ConTeXt.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (let ((value (org-element-property :value latex-fragment)))
    ;; Trim math markers since the fragment is enclosed within
    ;; a latex-math-block object anyway.
    (cond ((string-match-p "\\`\\$[^$]" value) (substring value 1 -1))
          ((string-prefix-p "\\(" value) (substring value 2 -2))
          ((or
            (string-prefix-p "\\[" value)
            (string-prefix-p "$$" value))
           (concat
            (when (plist-get info :context-number-equations)
              "\\placeformula\n")
            (format "\\startformula\n%s\n\\stopformula"
                    (substring value 2 -2))))
          (t value))))

;;;; Line Break

(defun org-context-line-break (_line-break _contents _info)
  "Transcode a LINE-BREAK object from Org to LaTeX.
CONTENTS is nil.  INFO is a plist holding contextual information."
  "\\crlf\n")

;;;; Link

(defun org-context-link (link desc info)
  "Transcode a LINK object from Org to ConTeXt.

DESC is the description part of the link, or the empty string.
INFO is a plist holding contextual information. See
`org-export-data'."
  (let* ((type (org-element-property :type link))
         (raw-path (org-element-property :path link))
         (desc (and (not (string= desc "")) desc))
         (imagep (org-export-inline-image-p
                  link
                  (plist-get info :context-inline-image-rules)))
         (path (org-context--protect-url
                (pcase type
                  ((or "http" "https" "ftp" "mailto" "doi")
                   (concat type ":" raw-path))
                  ("file"
                   (org-export-file-uri raw-path))
                  (_
                   raw-path)))))
    (cond
     ;; Image file.
     (imagep (org-context--inline-image link info))
     ;; Radio link: Transcode target's contents and use them as link's
     ;; description.
     ((string= type "radio")
      (let ((destination (org-export-resolve-radio-link link info)))
        (if (not destination)
            desc
          (format "\\goto{%s}[%s]"
                  desc
                  (org-export-get-reference destination info)))))
     ;; Links pointing to a headline: Find destination and build
     ;; appropriate referencing command.
     ((member type '("custom-id" "fuzzy" "id"))
      (let ((destination
             (if (string= type "fuzzy")
                 (org-export-resolve-fuzzy-link link info 'latex-matrices)
               (org-export-resolve-id-link link info))))
        (cl-case (org-element-type destination)
          ;; Id link points to an external file
          (plain-text
           (if desc
               (format "\\goto{%s}[url(%s)]" desc destination)
             (format "\\goto{\\hyphenatedurl{%s}}[url(%s)]" destination destination)))
          ;; Fuzzy link points nowhere
          ((nil)
           (format "\\hyphenatedurl{%s}" (org-element-property :raw-link link)))
          ;; LINK points to a headline.  If headlines are numbered
          ;; and the link has no description, display headline's
          ;; number.  Otherwise, display description or headline's
          ;; title.
          (otherwise
           (let ((label (org-context--label destination info t)))
             (if (not desc)
                 (format "\\goto{\\ref[default][%s]}[%s]" label label)
               (format "\\goto{%s}[%s]" desc label)))))))
     ;; Coderef: replace link with the reference name or the
     ;; equivalent line number.
     ((string= type "coderef")
      (let* ((code-block (org-context--find-coderef-parent raw-path info))
             (ref-label (org-context--get-coderef-label
                         raw-path code-block info))
             (linenum (org-export-get-loc code-block info))
             (retain-labels (org-element-property :retain-labels code-block)))
        (cond ((and linenum (not retain-labels))
               (format "\\inline{ }[%s]" ref-label))
              ((not retain-labels)
               (format "\\goto{\\ref[default][%s]}[%s]" ref-label ref-label))
              (t (format "\\goto{%s}[%s]" path ref-label)))))
     ;; External link with a description part.
     ((and path desc) (format "\\goto{%s}[url(%s)]" desc path))
     ;; External link without a description part.
     (path (format "\\goto{\\hyphenatedurl{%s}}[url(%s)]" path path))
     ;; No path, only description.  Try to do something useful.
     (t (format "\\hyphenatedurl{%s}" desc)))))

(defun org-context--inline-image (link info)
  "Return the ConTeXt code for an inline image.
LINK is the link pointing to the inline image. INFO is a plist
used as a communication channel."
  (let* ((case-fold-search t)
         (parent (org-export-get-parent-element link))
         (path (let ((raw-path (org-element-property :path link)))
                 (if (not (file-name-absolute-p raw-path)) raw-path
                   (expand-file-name raw-path))))
         (attr-latex (org-export-read-attribute :attr_latex parent))
         (attr-context (org-export-read-attribute :attr_context parent))
         ;; Context takes precedence over latex
         (attr (or attr-context attr-latex))
         (caption (org-context--caption/label-string parent info))
         (label (org-context--label parent info ))
         (floatp (not (org-element-lineage link '(table-cell))))
         (float (let ((float (plist-get attr :float)))
                  (cond ((string= float "wrap") 'wrap)
                        ((string= float "sideways") 'sideways)
                        ((string= float "multicolumn") 'multicolumn))))
         (scale (cond ((plist-get attr :scale))
                      (t (and (not (plist-member attr :scale))
                              (let ((scales (plist-get info :context-image-default-scale)))
                                (cdr (or (assoc float scales)
                                         (assoc t scales))))))))
         (width (cond ((org-string-nw-p scale) "")
                      ((plist-get attr :width))
                      ((plist-get attr :height) "")
                      (t (and (not (plist-member attr :width))
                              (let ((widths (plist-get info :context-image-default-width)))
                                (cdr (or (assoc float widths)
                                         (assoc t widths))))))))
         (height (cond ((org-string-nw-p scale) "")
                       ((plist-get attr :height))
                       ((or (plist-get attr :width)
                            (memq float '(figure wrap))) "")
                       (t (and (not (plist-member attr :height))
                               (let ((heights (plist-get info :context-image-default-height)))
                                 (cdr (or (assoc float heights)
                                          (assoc t heights))))))))
         (placement (or
                     (plist-get attr :placement)
                     (plist-get info :context-float-default-placement)))
         (options (let ((opt (or (plist-get attr :options)
                                 (plist-get info :context-image-default-option))))
                    (if (string-match "\\`\\[\\(.*\\)\\]\\'" opt)
                        (match-string 1 opt)
                      (org-string-nw-p opt))))
         image-code
         options-list)
    (and (org-string-nw-p scale)
         (push (cons "scale" scale) options-list))
    (and (org-string-nw-p width)
         (push (cons "width" width) options-list))
    (and (org-string-nw-p height)
         (push (cons "height" height) options-list))
    (setq image-code
          (format "\\externalfigure[%s][%s]"
                  path
                  (if options
                      (concat
                       options
                       ","
                       (org-context--format-arguments options-list))
                    (org-context--format-arguments options-list))))
    (let (env-options
          location-options)
      (push placement location-options)
      (pcase float
        (`wrap (push "here" location-options))
        (`sideways (progn (push "90" location-options)
                          (push "page" location-options)))
        (_ (or placement (push "here" location-options))))
      (push
       (cons "location"
             (mapconcat 'identity (delq nil (delete-dups location-options)) ","))
            env-options)
      (push (cons "reference" label) env-options)
      (when (org-string-nw-p caption)
        (push (cons "title" caption) env-options))
      (if floatp
          (format
           "\\startplacefigure[%s]
%s
\\stopplacefigure"
       (org-context--format-arguments env-options)
       image-code)
        image-code))))

;;;; Math Block

(defun org-context-math-block (_math-block contents _info)
  "Transcode a MATH-BLOCK object from Org to ConTeXt.
CONTENTS is a string.  INFO is a plist used as a communication
channel."
  (when (org-string-nw-p contents)
    (format "\\m{%s}" (org-trim contents))))

;;;; Node Property

(defun org-context-node-property (node-property _contents info)
  "Transcode a NODE-PROPERTY element from Org to ConTeXt.
CONTENTS is nil. INFO is a plist holding contextual information."
  (let ((command
         (org-string-nw-p
          (car
           (plist-get info :context-node-property-command))))
        (key (org-element-property :key node-property))
        (value (org-element-property :value node-property)))
    (if command
        (let ((args (org-context--format-arguments
                     (list (cons "key" key) (cons "value" value)))))
          (format "\\%s[%s]" command args))
      (format "%s:%s" key value))))

;;;; Paragraph

(defun org-context-paragraph (_paragraph contents info)
  "Transcode a PARAGRAPH element from Org to ConTeXt.
CONTENTS is the contents of the paragraph, as a string.  INFO is
the plist used as a communication channel."
  (org-context--text-markup contents 'paragraph info))

;;;; Plain List

(defun org-context-plain-list (plain-list contents info)
  "Transcode a PLAIN-LIST element from Org to ContTeXt.
CONTENTS is the contents of the list. INFO is a plist holding
contextual information."
  (let* ((type (org-element-property :type plain-list))
         (bullet
          (org-element-property
           :bullet
           (car (org-element-map plain-list 'item #'identity t))))
         (alphap (string-match-p "\\`[a-zA-Z][.)]" bullet))
         (upperp (and alphap
                      (let ((case-fold-search nil))
                        (string-match-p "\\`[[:upper:]]" bullet))))
         (open-command
          (cond ((eq type 'ordered)
                 (format  "\\startitemize[%s]\n"
                          (if alphap (if upperp "A" "a") "n")))
                ((eq type 'descriptive) "")
                (t "\\startitemize\n")))
         (close-command
          (if (eq type 'descriptive)
              ""
            "\\stopitemize")))
    (org-context--add-reference
     plain-list
     (concat
      open-command
      contents
      close-command)
     info)))

;;;; Plain Text

(defun org-context-plain-text (text info)
  "Transcode a TEXT string from Org to ConTeXt.
TEXT is the string to transcode.  INFO is a plist holding
contextual information."
  (let* ((specialp (plist-get info :with-special-strings))
	 (output
	  ;; Turn LaTeX into \LaTeX{} and TeX into \TeX{}.
	  (let ((case-fold-search nil))
	    (replace-regexp-in-string
	     "\\<\\(?:\\(?:La\\)?TeX\\)\\|\\(?:ConTeXt\\)\\>" "\\\\\\&{}"
	     ;; Protect special characters.
	     ;; However, if special strings are used, be careful not
	     ;; to protect "\" in "\-" constructs.
	     (replace-regexp-in-string
	      (concat "[][|\\{}#%~$]\\|\\\\" (and specialp "\\([^-]\\|$\\)"))
	      (lambda (m)
                (pcase (string-to-char m)
                  (?\\ "\\\\letterbackslash ")
                  (?~  "\\\\lettertilde ")
                  (_ "\\\\\\&")))
	      text)))))
    (when (plist-get info :with-smart-quotes)
      (setq output (org-context--format-quote output info text)))
    ;; Convert special strings.
    (when specialp
      (setq output (replace-regexp-in-string "\\.\\.\\." "\\\\ldots{}" output)))
    ;; Handle break preservation if required.
    (when (plist-get info :preserve-breaks)
      (setq output (replace-regexp-in-string
		    "\\(?:[ \t]*\\\\\\\\\\)?[ \t]*\n" "\\\\\n" output nil t)))
    output))

;;;; Planning

(defun org-context-planning (planning _contents info)
  "Transcode a PLANNING element from Org to ConTeXt.
CONTENTS is nil.  INFO is a plist holding contextual
information."
  (let ((closed (org-element-property :closed planning))
        (deadline (org-element-property :deadline planning))
        (scheduled (org-element-property :scheduled planning))
        (formatter (plist-get info :context-format-timestamp-function))
        (command-name (org-string-nw-p
                       (car (plist-get info :context-planning-command)))))
    (if command-name
        (concat (format "\\%s[" command-name)
                (when closed
                  (concat
                   (format "\nClosedString={%s}," org-closed-string)
                   (format "\nClosedTime={%s}," (funcall formatter closed))))
                (when deadline
                  (concat
                   (format "\nDeadlineString={%s}," org-deadline-string)
                   (format "\nDeadlineTime={%s}," (funcall formatter deadline))))
                (when scheduled
                  (concat
                   (format "\nScheduledString={%s}," org-scheduled-string)
                   (format "\nScheduledTime={%s}," (funcall formatter scheduled))))
                "]")
      (concat
       (when closed (concat org-closed-string (funcall formatter closed)))
       (when deadline (concat org-deadline-string (funcall formatter deadline)))
       (when scheduled (concat org-scheduled-string (funcall formatter scheduled)))))))

;;;; Property Drawer

(defun org-context-property-drawer (property-drawer contents info)
  "Transcode a PROPERTY-DRAWER element from Org to LaTeX.
CONTENTS holds the contents of the drawer.  INFO is a plist
holding contextual information."
  (when (org-string-nw-p contents)
    (org-context--wrap-env
     property-drawer
     contents
     info
     :context-property-drawer-environment)))

;;;; Quote Block

(defun org-context-quote-block (quote-block contents info)
  "Transcodes a QUOTE-BLOCK element from Org to ConTeXt.
CONTENTS is the contents of the block. INFO is a plist containing
contextual information."
  (when (org-string-nw-p contents)
    (org-context--enumerated-block
     quote-block contents info
     :context-blockquote-environment
     :context-enumerate-blockquote-environment
     :context-enumerate-blockquote-empty-environment)))

(defun org-context--format-quote (text info original)
  "Wraps quoted text in `\\quote{}' constructs.
ConTeXt provides facilities for multilingual quoting so
no need to reimplement. TEXT is the text to quote.
INFO is a plist containing contextual information.
ORIGINAL is the original unfiltered text."
  (let* ((quote-status
          (copy-sequence (org-export--smart-quote-status (or original text) info)))
        (quote-defs (plist-get info :context-export-quotes-alist))
        closing-stack
        ;; Try matching everything
        (matched-string
         (replace-regexp-in-string
         "['\"]"
         (lambda (_match)
           (let ((last-quote (pop quote-status)))
             ;; Because we're using ConTeXt quotation macros, we are sensitive to
             ;; mismatched opening/closing delimiters.
             (pcase last-quote
               ('primary-opening
                (setq closing-stack (cons 'primary-closing closing-stack)))
               ('secondary-opening
                (setq closing-stack (cons 'secondary-closing closing-stack)))
               ('primary-closing
                (if
                    (eq (car closing-stack) 'primary-closing)
                    (setq closing-stack (cdr closing-stack))
                  (error "Mismatched opening and closing quotations")))
               ('secondary-closing
                (if
                    (eq (car closing-stack) 'secondary-closing)
                    (setq closing-stack (cdr closing-stack))
                  (error "Mismatched opening and closing quotations"))))
             (cdr (assq last-quote quote-defs))))
         text nil t)))
    ;; If closing-stack is not nil, then something went wrong.
    ;; Don't bother with smart quotes in this case
    (if closing-stack
        text
      matched-string)))

;;;; Radio Target

(defun org-context-radio-target (radio-target text info)
  "Transcode a RADIO-TARGET object from Org to ConTeXt.
TEXT is the text of the target.  INFO is a plist holding
contextual information."
  (format "\\reference[%s]{%s} %s"
          (org-export-get-reference radio-target info)
          text
          text))

;;;; Section

(defun org-context-section (_section contents _info)
  "Transcode a SECTION element from Org to ConTeXt.
CONTENTS holds the contents of the section.  INFO is a plist
holding contextual information."
  contents)

;;;; Special Block

(defun org-context-special-block (special-block contents _info)
  "Transcode a SPECIAL-BLOCK element from Org to ConTeXt.
CONTENTS holds the contents of the block. INFO is a plist
holding contextual information."
  (let ((type (org-element-property :type special-block))
        (opt (org-export-read-attribute :attr_context special-block :options)))
    (concat (format "\\start%s%s\n"
                    type
                    (if opt (format "[%s]" opt) ""))
            contents
            (format "\n\\stop%s" type))))

;;;; Src Block

(defun org-context-src-block (src-block _contents info)
  "Transcode a SRC-BLOCK element from Org to LaTeX.
CONTENTS holds the contents of the item. INFO is a plist holding
contextual information."
  (let* ((caption
          (org-string-nw-p
           (org-trim
            (org-export-data
             (or (org-export-get-caption src-block t)
                 (org-export-get-caption src-block))
             info))))
         (environment
          (car
           (plist-get info
                      (if caption
                          :context-enumerate-listing-environment
                        :context-enumerate-listing-empty-environment))))
         (label (org-context--label src-block info t))
         (code (org-context--preprocess-source-block src-block info)))
    (let ((engine (plist-get info :context-syntax-engine))
          (args (org-context--format-arguments
                 (list
                  (cons "location" "force,split")
                  (cons "title" caption)
                  (cons "reference" label)))))
      (concat
       (format "\\start%s
  [%s]\n"
               environment args)
       (pcase engine
         ('vim (org-context--highlight-src-block-vim
                src-block code info))
         (_ (org-context--highlight-src-block-builtin
             src-block code info)))
       "\n"
       (format "\\stop%s" environment)))))

(defun org-context--preprocess-source-block (src-block info)
  "Format SRC-BLOCK with inline refs.
INFO is a plist containing contextual information."
  (let* ((code-info (org-export-unravel-code src-block))
         (code (car code-info))
         (refs (cdr code-info))
         (num-start (org-export-get-loc src-block info))
         (retain-labels (org-element-property :retain-labels src-block))
         (line-num 0)
         (reference-command (plist-get info :context-source-label))
         (reffed-code
          (mapconcat
           (lambda (line)
             (cl-incf line-num)
             (let* ((line-ref (assoc line-num refs))
                    (ref (cdr line-ref))
                    (ref-label (org-context--get-coderef-label
                                ref src-block info)))
               (concat
                line
                (when ref
                  (format "    /BTEX%s/ETEX"
                   (concat
                    (cond ((and num-start (not retain-labels))
                           (format "\\someline[%s]" ref-label))
                          ((not retain-labels)
                           (format "\\reference[%s]{%d}" ref-label line-num))
                          (t (format "\\reference[%s]{%s}" ref-label ref)))
                      (when (and (org-element-property :retain-labels src-block)
                                 reference-command)
                        (format reference-command ref))))))))
           (split-string code "\n")
           "\n")))
    reffed-code))

(defun org-context--highlight-src-block-builtin (src-block code info)
  "Wraps a source block in the builtin environment for ConTeXt source code.
Use this if you don't have Vim.

SRC-BLOCK is the code object to transcode. CODE is the
preprocessed contents of the code block. INFO is a plist holding
contextual information."
  (let* ((lang (org-context--get-builtin-lang-name src-block info))
         (env-name
          (or
           (org-string-nw-p
            (car (plist-get info :context-block-source-environment)))
           "typing"))
         (num-start (org-export-get-loc src-block info))
         (num-start-str
          (when (and num-start (> num-start 0))
            (number-to-string (+ 1 num-start))))
         (args
          (org-string-nw-p
           (org-context--format-arguments
            (list (cons "start" num-start-str)
                  (cons "numbering" (when num-start "line"))
                  (cons "option" lang))
            t))))
    (format "\\start%s%s\n%s\n\\stop%s"
            env-name
            (if args (format "[%s]" args) "")
            code
            env-name)))

(defun org-context--highlight-src-block-vim (src-block code info)
  "Wraps a source block in a vimtyping environment.
This requires you have Vim installed and the t-vim module for
ConTeXt. SRC-BLOCK is the entity to wrap. CODE is the contents of
the entity. INFO is a plist containing contextual information."
  (let* ((lang-info (org-context--get-vim-lang-info src-block info))
         (context-name (plist-get lang-info :context-block-name))
         (num-start (org-export-get-loc src-block info))
         (num-start-str
          (when (and num-start (> num-start 0))
            (number-to-string (+ 1 num-start))))
         (args
          (org-string-nw-p
           (org-context--format-arguments
            (list (cons "numberstart" num-start-str)
                  (cons "numbering" (when num-start "yes")))
            t))))
    (if context-name
        (format "\\start%s%s\n%s\n\\stop%s"
                context-name
                (if args (format "[%s]" args) "")
                code
                context-name)
      (format "\\starttyping\n%s\\stoptying" code))))

;;;; Statistics Cookie

(defun org-context-statistics-cookie (statistics-cookie _contents _info)
  "Transcode a STATISTICS-COOKIE object from Org to ConTeXt.
CONTENTS is nil. INFO is a plist holding contextual information."
  (replace-regexp-in-string
   "%" "\\%" (org-element-property :value statistics-cookie) nil t))

;;;; Strike-Through

(defun org-context-strike-through (_strike-through contents info)
  "Transcode STRIKE_THROUGH from Org to ConTeXt.
CONTENTS is the contents to strike out. INFO is a plist contextual information."
  (org-context--text-markup contents 'strike-through info))

;;;; Subscript

(defun org-context-subscript (_subscript contents info)
  "Transcode a SUBSCRIPT from Org to ConTeXt.
CONTENTS is the content to subscript. INFO is a plist containing
contextual information."
  (org-context--text-markup contents 'subscript info))

;;;; Superscript

(defun org-context-superscript (_superscript contents info)
  "Transcode a SUPERSCRIPT from Org to ConTeXt.
CONTENTS is the content to subscript. INFO is a plist containing
contextual information."
  (org-context--text-markup contents 'superscript info))

;;;; Table Cell

(defun org-context-table-cell (table-cell contents info)
  "Transcode a TABLE-CELL from Org to ConTeXt.
CONTENTS is the cell contents. INFO is a plist used as
a communication channel."
  (let* ((table (org-export-get-parent-table table-cell))
         (table-row (org-export-get-parent table-cell))
         (alignment (org-export-table-cell-alignment table-cell info))
         (attr (org-export-read-attribute :attr_context table))
         (first-row-p (not (org-export-get-previous-element table-row info)))
         (last-row-p (not (org-export-get-next-element table-row info)))
         (first-col-p (not (org-export-get-previous-element table-cell info)))
         (last-col-p (not (org-export-get-next-element table-cell info)))
         (starts-colgroup-p (org-export-table-cell-starts-colgroup-p table-cell info))
         (ends-colgroup-p (org-export-table-cell-ends-colgroup-p table-cell info))
         (first-col-style (or (plist-get attr :w)
                             (org-string-nw-p
                              (car (plist-get info :context-table-leftcol-style)))))
         (last-col-style (or (plist-get attr :e)
                            (org-string-nw-p
                             (car (plist-get info :context-table-rightcol-style)))))
         (top-left-style (or (plist-get attr :nw)
                            (org-string-nw-p
                             (car (plist-get info :context-table-topleft-style)))))
         (top-right-style (or (plist-get attr :ne)
                             (org-string-nw-p
                              (car (plist-get info :context-table-topright-style)))))
         (bottom-left-style (or (plist-get attr :sw)
                               (org-string-nw-p
                                (car (plist-get info :context-table-bottomleft-style)))))
         (bottom-right-style (or (plist-get attr :se)
                                (org-string-nw-p
                                 (car (plist-get info :context-table-bottomright-style)))))
         (starts-colgroup-style (or (plist-get attr :cgs)
                                    (org-string-nw-p
                                     (car (plist-get info :context-table-colgroup-start-style)))))
         (ends-colgroup-style (or (plist-get attr :cge)
                                    (org-string-nw-p
                                     (car (plist-get info :context-table-colgroup-end-style)))))
         (suffix
          (cond ((and first-row-p first-col-p top-left-style) (format "[%s]" top-left-style))
                ((and first-row-p last-col-p top-right-style) (format "[%s]" top-right-style))
                ((and last-row-p first-col-p bottom-left-style) (format "[%s]" bottom-left-style))
                ((and last-row-p last-col-p bottom-right-style) (format "[%s]" bottom-right-style))
                ((and first-col-p first-col-style) (format "[%s]" first-col-style))
                ((and last-col-p last-col-style) (format "[%s]" last-col-style))
                ((and starts-colgroup-p starts-colgroup-style)
                 (format "[%s]" starts-colgroup-style))
                ((and ends-colgroup-p ends-colgroup-style)
                 (format "[%s]" ends-colgroup-style))
                (t "")))
         ;; TODO Consider not applying alignment to contents if alignment not specified
         (alignspec (pcase alignment
                      ('left "\\startalignment[flushleft] %s \\stopalignment")
                      ('right "\\startalignment[flushright] %s \\stopalignment")
                      ('center "\\startalignment[middle] %s \\stopalignment"))))
    (concat
     (format "\\startxcell%s " suffix)
     (when contents (format alignspec contents))
     " \\stopxcell\n")))

;;;; Table Row

(defun org-context-table-row (table-row contents info)
  "Transcode a TABLE-ROW element from Org to ConTeXt.
CONTENTS is the contents of the row.  INFO is a plist used as
a communication channel."
  (let* ((table (org-export-get-parent-table table-row))
         (attr (org-export-read-attribute :attr_context table))
         (dimensions (org-export-table-dimensions table info))
         (row-num (or (org-export-table-row-number table-row info) 0))
         (row-group-num (or (org-export-table-row-group table-row info) 0))
         (headerp (org-export-table-row-in-header-p table-row info))
         (last-row-num (org-export-get-parent-element
                        (org-export-get-table-cell-at
                         (cons (- (car dimensions) 1) (- (cdr dimensions) 1))
                         table info)))
         (last-row-group-num (org-export-table-row-group last-row-num info))
         (table-has-footer-p
          ;; Table has a footer if it has 3 or more row groups and footer
          ;; is selected
          (and (> last-row-group-num 2)
               (or (plist-member attr :f)
                   (string= "repeat"
                            (org-export-data
                             (plist-get attr :footer)
                             info))
                   (org-string-nw-p
                    (org-export-data (plist-get info :context-table-footer) info)))))
         (last-row-group-p (and row-group-num (= row-group-num last-row-group-num)))
         (footerp (and last-row-group-p table-has-footer-p))
         (first-body-group-p
          (if (org-export-table-has-header-p table info)
              (= row-group-num 2)
            (= row-group-num 1)))
         (last-body-group-p
          (if table-has-footer-p
              (and row-group-num (= row-group-num (- last-row-group-num 1)))
            last-row-group-p))
         (header-style (or (plist-get attr :h)
                           (org-string-nw-p
                            (car (plist-get info :context-table-header-style)))))
         (footer-style (or (plist-get attr :f)
                           (org-string-nw-p
                            (car (plist-get info :context-table-footer-style)))))
         (body-style (or (plist-get attr :b)
                           (org-string-nw-p
                            (car (plist-get info :context-table-body-style)))))
         (header-mid-row-style
          (or (plist-get attr :hm)
              (org-string-nw-p
               (car (plist-get info :context-table-header-mid-style)))))
         (footer-mid-row-style
          (or (plist-get attr :fm)
              (org-string-nw-p
               (car (plist-get info :context-table-footer-mid-style)))))
         (header-top-row-style
          (or (plist-get attr :ht)
              (org-string-nw-p
               (car (plist-get info :context-table-header-top-style)))))
         (footer-top-row-style
          (or (plist-get attr :ft)
              (org-string-nw-p
               (car (plist-get info :context-table-footer-top-style)))))
         (header-bottom-row-style
          (or (plist-get attr :hb)
              (org-string-nw-p
               (car (plist-get info :context-table-header-bottom-style)))))
         (footer-bottom-row-style
          (or (plist-get attr :hb)
              (org-string-nw-p
               (car (plist-get info :context-table-footer-bottom-style)))))
         (row-group-start-style
          (or (plist-get attr :rgs)
              (org-string-nw-p
               (car (plist-get info :context-table-rowgroup-start-style)))))
         (row-group-end-style
          (or (plist-get attr :rge)
              (org-string-nw-p
               (car (plist-get info :context-table-rowgroup-end-style)))))
         (first-row-style
          (or
           (or (plist-get attr :n)
               (org-string-nw-p
                (car (plist-get info :context-table-toprow-style))))
           row-group-start-style))
         (last-row-style
          (or
           (or (plist-get attr :s)
               (org-string-nw-p
                (car (plist-get info :context-table-bottomrow-style))))
           row-group-end-style))
         (first-row-p (= row-num 0))
         (last-row-p (= row-num (- (car dimensions) 1)))
         (starts-row-group-p (org-export-table-row-starts-rowgroup-p table-row info))
         (ends-row-group-p (org-export-table-row-ends-rowgroup-p table-row info))
         (wrappedcontents
          (when contents
            (format "\\startxrow%s\n%s\\stopxrow\n"
                    (cond ((and headerp
                                (org-export-table-row-starts-header-p table-row info)
                                (org-export-table-row-ends-header-p table-row info))
                           "")
                          ((and headerp
                                (org-export-table-row-starts-header-p table-row info)
                                header-top-row-style)
                           (format "[%s]" header-top-row-style))
                          ((and headerp
                                (org-export-table-row-ends-header-p table-row info)
                                header-bottom-row-style)
                           (format "[%s]" header-bottom-row-style))
                          ((and headerp header-mid-row-style)
                           (format "[%s]" header-mid-row-style))
                          ;; footer
                          ((and footerp
                                (org-export-table-row-starts-rowgroup-p table-row info)
                                (org-export-table-row-ends-rowgroup-p table-row info))
                           "")
                          ((and footerp
                                (org-export-table-row-starts-rowgroup-p table-row info)
                                footer-top-row-style)
                           (format "[%s]" footer-top-row-style))
                          ((and footerp
                                (org-export-table-row-ends-rowgroup-p table-row info)
                                footer-bottom-row-style)
                           (format "[%s]" footer-bottom-row-style))
                          ((and footerp footer-mid-row-style)
                           (format "[%s]" footer-mid-row-style))
                          ((and first-row-p first-row-style)
                           (format "[%s]" first-row-style))
                          ((and last-row-p last-row-style)
                           (format "[%s]" last-row-style))
                          ((and ends-row-group-p row-group-end-style)
                           (format "[%s]" row-group-end-style))
                          ((and starts-row-group-p row-group-start-style)
                           (format "[%s]" row-group-start-style))
                          (t ""))
                    contents)))
         (group-tags
          (cond
           (headerp
            (list "\\startxtablehead%s\n" header-style "\\stopxtablehead"))
           (footerp
            (list "\\startxtablefoot%s\n" footer-style "\\stopxtablefoot")))))
    (concat
     (and starts-row-group-p first-body-group-p
       (format "\\startxtablebody%s\n"
               (if (org-string-nw-p body-style)
                   (format "[%s]" body-style)
                 "")))
     (and starts-row-group-p group-tags
                 (format (nth 0 group-tags)
                         (if (org-string-nw-p (nth 1 group-tags))
                             (format "[%s]" (nth 1 group-tags))
                           "")))
     wrappedcontents
     (and ends-row-group-p group-tags (nth 2 group-tags))
     (and ends-row-group-p last-body-group-p "\\stopxtablebody"))))

;;;; Table

(defun org-context-table (table contents info)
  "Return appropriate ConTeXt code for an Org table.

TABLE is the table type element to transcode.  CONTENTS is its
contents, as a string.  INFO is a plist used as a communication
channel.

This function assumes TABLE has `org' as its `:type' property and
`table' as its `:mode' attribute."

  (let* ((attr (org-export-read-attribute :attr_context table))
         (caption (org-context--caption/label-string table info))
         (label (org-context--label table info t))
         (location (or (plist-get attr :location)
                       (org-export-data (plist-get info :context-table-location) info)))
         (header (or (plist-get attr :header)
                     (org-export-data (plist-get info :context-table-header) info)))
         (footer (or (plist-get attr :footer)
                     (org-export-data (plist-get info :context-table-footer) info)))
         (option (or (plist-get attr :option)
                     (org-export-data (plist-get info :context-table-option) info)))
         (table-style (or (plist-get attr :table-style)
                    (org-export-data (plist-get info :context-table-style) info)))
         (float-style (or (plist-get attr :float-style)
                          (org-export-data (plist-get info :context-table-float-style) info)))
         (split (or (let ((split (plist-get attr :split)))
                      (and (org-string-nw-p split)
                           (if (string= split "t")
                               "yes"
                             split)))
                    (org-export-data (plist-get info :context-table-split) info)))
         (location-string (concat (when (string= split "yes") "split,") location))
         (float-args (org-context--format-arguments
                      (list
                       (cons "location" location-string)
                       (cons "title" caption)
                       (cons "reference" label))))
         (table-args (org-context--format-arguments
                      (list
                       (cons "split" split)
                       (cons "header" header)
                       (cons "footer" footer)
                       (cons "option" option))))
         (first-row (org-element-map table 'table-row
                      (lambda (row)
                        (and (eq (org-element-property :type row) 'standard) row))
                      info 'first-match))
         (cells
          (org-element-map first-row 'table-cell 'identity))
         (widths
          (mapcar (lambda (cell)
                    (let* ((raw-width (org-export-table-cell-width cell info)))
                      (if raw-width (format "[width=%.2fem]" raw-width) "")))
                  cells)))
    (concat
     (format
      "\\startplacetable%s
\\startxtable%s%s
%s"
      (if (org-string-nw-p float-style) (format "\n[%s]" float-style)
        (if (org-string-nw-p float-args) (format "\n[%s]" float-args) ""))
      (if (org-string-nw-p table-style) (format "\n[%s]" table-style) "")
      (if (org-string-nw-p table-args) (format "\n[%s]" table-args) "")
      contents)
     (when (cl-some 'org-string-nw-p widths)
       (concat
        "\\startxrow[empty=yes,offset=-1pt,height=0pt]\n"
        (mapconcat (lambda (w)
                     (if w
                         (format "\\startxcell%s\\stopxcell" w)
                       "\\startxcell\\stopxcell"))
                   widths
                   "\n")
        "\n\\stopxrow"))
     "\\stopxtable
\\stopplacetable\n"
     (org-context--delayed-footnotes-definitions table info))))

;;;; Target

(defun org-context-target (target _contents info)
  "Transcode a TARGET object from Org to ConTeXt.
CONTENTS is nil.  INFO is a plist holding contextual
information."
  (format "\\reference[%s]{%s}" (org-context--label target info)
          (org-export-get-node-property :value target)))

;;;; Template

(defun org-context-template (contents info)
  "Return complete document string after ConTeXt conversion.
CONTENTS is the transcoded contents string. INFO is a plist
holding the export options."
  (let* ((time-stamp (plist-get info :time-stamp-file))
         (header-lines (list (plist-get info :context-header)))
         (metadata (org-context--list-metadata info))
         (header-extra-lines (list (plist-get info :context-header-extra)))
         (preset-name (plist-get info :context-preset))
         (preset-data (cdr (assoc preset-name (plist-get info :context-presets))))
         (preset-header-string (plist-get preset-data :literal))
         (preset-header-snippets
          (org-context--get-snippet-text info (plist-get preset-data :snippets)))
         (user-snippets (org-context--get-snippet-text info (plist-get info :context-snippet)))
         (command-defs (org-context--get-definitions info))
         (unnumbered-headline-commands
          (let* ((notoc-headline-commands
                  (org-context--get-all-headline-commands
                   (lambda (headline inf)
                     (org-export-excluded-from-toc-p headline inf))
                   info))
                 (commands
                  (mapcar
                     (lambda (command)
                       (format "\\definehead[%s][%s]"
                                 command
                                 (string-remove-suffix "NoToc" command)))
                     notoc-headline-commands)))
            (mapconcat
             #'identity
             commands
             "\n")))
         (vimp (eq (plist-get info :context-syntax-engine) 'vim))
         (vim-langs
          (let* ((vim-lang-hash (when vimp
                                  (plist-get info :context-languages-used-cache))))
            (when (and vimp vim-lang-hash)
              (mapconcat
               (lambda (key)
                 (let* ((lang-info (gethash key vim-lang-hash))
                        (vim-lang (plist-get lang-info :vim-lang))
                        (context-inline-name (plist-get lang-info :context-inline-name))
                        (context-block-name (plist-get lang-info :context-block-name))
                        (def-template "\\definevimtyping[%s]\n  [syntax=%s,escape=command]\n"))
                   (concat
                    (format def-template
                            context-inline-name vim-lang)
                    (format def-template
                            context-block-name vim-lang))))
               (hash-table-keys vim-lang-hash)
               "\n"))))
         (bib-place (plist-get info :context-bib-command))
         (toc-title-command (plist-get info :context-toc-title-command))
         (toc-commands
          (let ((with-toc (plist-get info :with-toc))
                (with-section-numbers (plist-get info :section-numbers)))
            (concat
             (when (and with-toc (not with-section-numbers))
               "% Add internal numbering to unnumbered sections so they can be included in TOC
\\setuphead[subject]
          [incrementnumber=yes,
            number=no]
\\setuphead[subsubject]
          [incrementnumber=yes,
            number=no]
\\setuphead[subsubsubject]
          [incrementnumber=yes,
            number=no]
\\setuphead[subsubsubsubject]
          [incrementnumber=yes,
            number=no]
")
             (when with-toc
               (format "%s
\\setupcombinedlist[content][list={%s}]\n"
                       (cdr toc-title-command)
                       (mapconcat
                        #'identity
                        (org-context--get-all-headline-commands
                         (lambda (hl inf)
                           (and (not (org-export-excluded-from-toc-p hl inf))
                                   (if (wholenump with-toc)
                                        (<= (org-export-get-relative-level hl inf) with-toc)
                                     t)))
                         info)
                        ",")))))))
    (concat
     (and time-stamp
          (format-time-string "%% Created %Y-%m-%d %a %H:%M\n"))
     (when vimp "\n\\usemodule[vim]")
     "\n"
     unnumbered-headline-commands
     (when bib-place (format "\n%s\n" bib-place))
     (when header-lines
       (concat
        "
%===============================================================================
% From CONTEXT_HEADER
%===============================================================================
"
        (mapconcat #'org-element-normalize-string
                   header-lines
                   "")))
     (when (org-string-nw-p toc-commands)
       (concat
        "
%===============================================================================
% Table of Contents Configuration
%===============================================================================
"
        toc-commands))
     "
%===============================================================================
% Document Metadata
%===============================================================================
"
     (format "\\setupdocument[%s]\n"
             (org-context--format-arguments metadata))
     (format "\\language[%s]" (cdr (assoc "metadata:language" metadata)))
     (when (or (org-string-nw-p vim-langs) (org-string-nw-p command-defs))
       (concat
        "
%===============================================================================
% Define Environments and Commands
%===============================================================================
"
        (when (org-string-nw-p vim-langs)
          (concat (org-trim vim-langs)
                  "\n"))
        (when (org-string-nw-p command-defs)
          (org-trim command-defs))))
     (when (or (org-string-nw-p preset-header-string)
                (org-string-nw-p preset-header-snippets))
       (concat
        "
%===============================================================================
% Preset Commands
%===============================================================================
"
        (org-trim preset-header-string)
        "\n"
        (org-trim (mapconcat 'identity preset-header-snippets "\n"))))
     (when user-snippets
       (concat
        "
%===============================================================================
% Snippet Commands
%===============================================================================
"
        (mapconcat 'identity user-snippets "\n")))
     (when header-extra-lines
       (concat
        "
%===============================================================================
% Commands from CONTEXT_HEADER_EXTRA
%===============================================================================
"
        (mapconcat #'org-element-normalize-string
                   header-extra-lines
                   "\n\n")))
     "
%===============================================================================
% Document Body
%===============================================================================
% Turn on interaction to make links work
\\setupinteraction[state=start]
\\starttext
\\placebookmarks
"
     contents
     "
\\stoptext\n")))

(defun org-context--get-definitions (info)
  "Scan INFO for all used elements that need ConTeXt definitions inserted.

Returns a string containing those definitions."
  (let* ((tree (plist-get info :parse-tree))
         (types (append org-element-all-objects org-element-all-elements))
         (elements (org-element-map tree types #'identity))
         (element-types (delq nil (delete-dups (mapcar #'car elements))))
         (deflist
           '((clock . ((:context-clock-command . "% Define a basic clock command")))
             (drawer . ((:context-drawer-command . "% Define a basic drawer command")))
             (example-block . ((:context-enumerate-example-empty-environment .
                                "% Create the unlabelled example enumeration environment")
                               (:context-enumerate-example-environment .
                                "% Create the example enumeration environment")
                               (:context-example-environment .
                                "% Create the example environment")))
             (fixed-width . ((:context-fixed-environment .
                        "% Create the fixed width environment")))
             (headline . ((:context-headline-command .
                           "% Define a basic headline command")))
             (inline-src-block . ((:context-inline-source-environment .
                                   "% Create the inline source environment")))
             (inlinetask . ((:context-inlinetask-command .
                             "% Define a basic inline task command")))
             (item . ((:context-bullet-on-command .
                       "% Define on bullet command")
                      (:context-bullet-off-command .
                       "% Define off bullet command")
                      (:context-bullet-trans-command .
                       "% Define incomplete bullet command")
                      (:context-description-command .
                       "% LaTeX-style descriptive enumerations")))
             (node-property . ((:context-node-property-command .
                                "% Define a command for node properties in drawers")))
             (planning . ((:context-planning-command .
                           "% Define a basic planning command")))
             (property-drawer . ((:context-property-drawer-environment .
                                  "% Create a property drawer style")))
             (quote-block . ((:context-blockquote-environment .
                              "% blockquote environment")
                             (:context-enumerate-blockquote-empty-environment .
                              "% Unlabelled blockquote enumeration environment")
                             (:context-enumerate-blockquote-environment .
                              "% blockquote enumeration environment")))
             (src-block . ((:context-block-source-environment .
                            "% Create the block source environment")
                           (:context-enumerate-listing-empty-environment .
                            "% Create the unlabelled listings enumeration environment")
                           (:context-enumerate-listing-environment .
                            "% Create the listings enumeration environment")))
             (verse-block . ((:context-enumerate-verse-empty-environment .
                              "% Create the unlabelled verse enumeration environment")
                             (:context-enumerate-verse-environment .
                              "% Create a verse enumeration environment")
                             (:context-verse-environment .
                              "% Create a verse style")))))
         (command-defs (mapconcat
                        ;; TODO don't add extra newlines
                        (lambda (elem)
                          (mapconcat
                           (lambda (def)
                             (let* ((kw (car def))
                                    (comment (cdr def))
                                    (nameimpl (plist-get info kw))
                                    (impl (cdr nameimpl)))
                               (concat comment "\n" (org-string-nw-p impl))))
                           (cdr (assoc elem deflist))
                           "\n"))
                        element-types
                        "\n"))
         (table-defs
          (mapconcat
           'identity
           (seq-filter
            'identity
            (delete-dups
             (mapcar
              (lambda
                (kw)
                (let* ((styledef (plist-get info kw))
                       (def (cdr styledef))
                       (style (car styledef)))
                  (if (org-string-nw-p def)
                      def
                    (format "\\setupxtable[%s][]" style))))
              (list :context-table-toprow-style
                    :context-table-bottomrow-style
                    :context-table-leftcol-style
                    :context-table-rightcol-style
                    :context-table-topleft-style
                    :context-table-topright-style
                    :context-table-bottomleft-style
                    :context-table-bottomright-style
                    :context-table-header-style
                    :context-table-footer-style
                    :context-table-header-top-style
                    :context-table-footer-top-style
                    :context-table-header-bottom-style
                    :context-table-footer-bottom-style
                    :context-table-header-mid-style
                    :context-table-footer-mid-style
                    :context-table-body-style
                    :context-table-rowgroup-start-style
                    :context-table-rowgroup-end-style
                    :context-table-colgroup-start-style
                    :context-table-colgroup-end-style))))
           "\n"))
         (keywords
          (seq-filter
           (lambda (elem) (equal 'keyword (car elem)))
           elements))
         (special-indices-by-keyword
          (mapcar
           (lambda (ix)
             (cons (plist-get (cdr ix) :keyword) ix))
           (plist-get info :context-texinfo-indices)))
         (used-keywords
          (delq
           nil
           (delete-dups
            (mapcar
             (lambda (kw) (org-element-property :key kw))
             (seq-filter
              (lambda (kw)
                (let ((key (org-element-property :key kw)))
                  (assoc key special-indices-by-keyword)))
              keywords)))))
         (index-defs
          (mapconcat
           (lambda (kw)
             (let* ((def (assoc kw special-indices-by-keyword))
                    (command (plist-get (cdr (cdr def)) :command)))
               (format "\\defineregister[%s]" command)))
           used-keywords
           "\n"))
         (headlines
          (org-element-map tree 'headline #'identity)))
    (concat
     command-defs
     "\n"
     (when (member 'table element-types) table-defs)
     "\n"
     index-defs)))

(defun org-context--get-max-headline-depth (info)
  "Scan INFO for all headlines and the maximum depth."
  (let ((levels
         (mapcar
          (lambda (headline)
            (org-element-property :level headline))
          (org-element-map
              (plist-get info :parse-tree)
              'headline
            #'identity))))
    (if levels (seq-max levels) 0)))

(defun org-context--list-metadata (info)
  "Create a `format-spec' for document meta-data.
INFO is a plist used as a communication channel."
  ;; TODO handle arbitrary metadata.
  (list
    (cons "metadata:author" (org-export-data (plist-get info :author) info))
    (cons "metadata:title" (org-export-data (plist-get info :title) info))
    (cons "metadata:email" (org-export-data (plist-get info :email) info))
    (cons "metadata:subtitle" (org-export-data (plist-get info :subtitle) info))
    (cons "metadata:keywords" (org-export-data (plist-get info :keywords) info))
    (cons "metadata:description" (org-export-data (plist-get info :description) info))
    (cons "metadata:creator" (plist-get info :creator))
    (cons "metadata:language" (plist-get info :language))
    (cons "Lang" (capitalize (plist-get info :language)))
    (cons "metadata:date" (org-export-data (org-export-get-date info) info))
    (cons "metadata:phonenumber" (org-export-data (plist-get info :phone-number) info))
    (cons "metadata:url" (org-export-data (plist-get info :url) info))
    (cons "metadata:subject" (org-export-data (plist-get info :subject) info))))

(defun org-context--get-snippet-text (info snippet-names)
  "Return snippets given a list of SNIPPET NAMES.
SNIPPET-NAMES is a list of snippet names to look up.
INFO is a plist used as a communication channel."
  (mapcar
   (lambda (snippet-name)
     (cdr (assoc
           snippet-name
           (plist-get info :context-snippets))))
   snippet-names))
 
;;;; Timestamp

(defun org-context-timestamp (timestamp _contents info)
  "Transcode a TIMESTAMP object from Org to ConTeXt.
CONTENTS is nil.  INFO is a plist holding contextual
information."
  (funcall (plist-get info :context-format-timestamp-function) timestamp))

(defun org-context-format-timestamp-default-function (timestamp)
  "Transcode a TIMESTAMP from Org to ConTeXt."
  (let* ((time (org-timestamp-to-time timestamp))
         (year (format-time-string "%Y" time))
         (month (format-time-string "%m" time))
         (day (format-time-string "%d")))
    (format "\\date[d=%s,m=%s,y=%s]" day month year)))

;;;; Underline

(defun org-context-underline (_underline contents info)
  "Transcode UNDERLINE from Org to ConTeXt.
CONTENTS is the content to underline. INFO is a plist containing
contextual information."
  (org-context--text-markup contents 'underline info))

;;;; Verbatim

(defun org-context-verbatim (verbatim _contents info)
  "Transcode a VERBATIM object from Org to ConTeXt.
CONTENTS is the content to mark up. INFO is a plist containing
contextual information."
  (org-context--text-markup
   (org-element-property :value verbatim) 'verbatim info))

;;;; Verse Block

(defun org-context-verse-block (verse-block contents info)
  "Transcode a VERSE-BLOCK element from Org to ConTeXt.
CONTENTS is verse block contents.  INFO is a plist holding
contextual information."
  (when (org-string-nw-p contents)
    (org-context--enumerated-block
     verse-block contents info
     :context-verse-environment
     :context-enumerate-verse-environment
     :context-enumerate-verse-empty-environment)))

;;; End-user functions

(defun org-context--collect-warnings (buffer)
  "Collect some warnings from \"pdflatex\" command output.
BUFFER is the buffer containing output.  Return collected
warnings types as a string, `error' if a ConTeXt error was
encountered or nil if there was none."
  (with-current-buffer buffer
    (save-excursion
      (goto-char (point-max))
      (when (re-search-backward "^[ \t]*This is .*?TeX.*?Version" nil t)
        (if (re-search-forward "^!" nil t) 'error
          (let ((case-fold-search t)
                (warnings ""))
            (dolist (warning org-latex-known-warnings)
              (when (save-excursion (re-search-forward (car warning) nil t))
                (setq warnings (concat warnings " " (cdr warning)))))
            (org-string-nw-p (org-trim warnings))))))))

;;;###autoload
(defun org-context-export-as-context
  (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer as a ConTeXt buffer.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting buffer should be accessible
through the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

When optional argument BODY-ONLY is non-nil, only write code
between \"\\starttext\" and \"\\stoptext\".

EXT-PLIST, when provided, is a property list with external
parameters overriding Org default settings, but still inferior to
file-local settings.

Export is done in a buffer named \"*Org CONTEXT Export*\", which
will be displayed when `org-export-show-temporary-export-buffer'
is non-nil."
  (interactive)
  (org-export-to-buffer 'context "*Org CONTEXT Export*"
    async subtreep visible-only body-only ext-plist (lambda () (ConTeXt-mode))))

;;;###autoload
(defun org-context-export-to-context
    (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to a ConTeXt file.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting file should be accessible through
the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

When optional argument BODY-ONLY is non-nil, only write code
between \"\\starttext\" and \"\\stoptext\".

EXT-PLIST, when provided, is a property list with external
parameters overriding Org default settings, but still inferior to
file-local settings."
  (interactive)
  (let ((file (org-export-output-file-name ".mkiv" subtreep)))
    (org-export-to-file 'context file
      async subtreep visible-only body-only ext-plist)))

;;;###autoload
(defun org-context-export-to-pdf
  (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to ConTeXt then process through to PDF.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting file should be accessible through
the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

When optional argument BODY-ONLY is non-nil, only write code
between \"\\starttext\" and \"\\stoptext\".

EXT-PLIST, when provided, is a property list with external
parameters overriding Org default settings, but still inferior to
file-local settings.

Return PDF file's name."
  (interactive)
  (let ((outfile (org-export-output-file-name ".mkiv" subtreep)))
    (org-export-to-file 'context outfile
      async subtreep visible-only body-only ext-plist
      (lambda (file) (org-context-compile file)))))

(defun org-context-compile (texfile &optional snippet)
  "Compile a ConTeXt file.

TEXFILE is the name of the file being compiled.  Processing is
done through the command specified in `org-context-pdf-process',
which see.  Output is redirected to \"*Org PDF ConTeXt Output*\"
buffer.

When optional argument SNIPPET is non-nil, TEXFILE is a temporary
file used to preview a LaTeX snippet.  In this case, do not
create a log buffer and do not remove log files.

Return PDF file name or raise an error if it couldn't be
produced."
  (unless snippet (message "Processing ConTeXt file %s..." texfile))
  (let* ((process org-context-pdf-process)
         (log-buf-name "*Org PDF ConTeXt Output*")
         (log-buf (and (not snippet) (get-buffer-create log-buf-name)))
         (outfile (org-compile-file texfile process "pdf"
                                    (format "See %S for details" log-buf-name)
                                    log-buf )))
    (unless snippet
      (when org-context-remove-logfiles
        (mapc #'delete-file
              (directory-files
               (file-name-directory outfile)
               t
               (format "%s\\(?:\\(?:%s\\)\\|\\(?:%s\\)\\)"
                       (regexp-quote (file-name-base outfile))
                       (concat "\\(?:\\.[0-9]+\\)?\\."
                               (regexp-opt org-context-logfiles-extensions))
                       "-temp-[[:alnum:]]+-[0-9]+\\.vimout")
               t)))
      ;; LaTeX warnings should be close enough to ConTeXt warnings
      (let ((warnings (org-context--collect-warnings log-buf)))
        (message (concat "PDF file produced"
                         (cond
                          ((eq warnings 'error) " with errors.")
                          (warnings (concat " with warnings: " warnings))
                          (t "."))))))
    ;; Return output file name.
    outfile))

(provide 'ox-context)
;;; ox-context.el ends here
