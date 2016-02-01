{**
  @abstract(This unit provides a wrapper around the standard fpc dom unit)

  see TTreeParserDOM
*}
unit simplexmltreeparserfpdom;

{
Copyright (C) 2008 - 2012 Benito van der Zander (BeniBela)
                          benito@benibela.de
                          www.benibela.de

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, simplehtmltreeparser, DOM, XMLRead,xmlutils;

type

{ TTreeParserDOM }

{** Base class for TTreeParserDOM *}
TTreeParserDOMBase = class(TTreeParser)
private
  fparser: TDOMParser;
public
  constructor Create;
  destructor destroy; override;

  //** Create a tree document from a standard fpc dom document
  function import(dom: TDOMDocument): TTreeDocument;
  //** Reads a tree document from a string, using the standard fpc dom functions to parse it
  function parseDOM(const document: String; const uri: string = ''): TTreeDocument;

  property Parser: TDOMParser read fparser;
end;

{** This class provides wrapper methods around the standard fpc DOM functions,
    to convert the TDOMDocument class created by fpc to the TTreeDocument class used by the XQuery engine.
*}
TTreeParserDOM = class(TTreeParserDOMBase)
  //** Reads a tree document from a string, using the standard fpc dom functions to parse it
  function parseTree(html: string; uri: string = ''; contentType: string = ''): TTreeDocument; override;
end;

implementation


{ TTreeParserDOM }

constructor TTreeParserDOMBase.Create;
begin
  inherited;
  fparser := TDOMParser.Create;
  fparser.Options.ExpandEntities := True;
  fparser.Options.CDSectionsAsText := True;
  fparser.Options.Namespaces := True;
  fparser.Options.PreserveWhitespace := True;
  fparser.Options.Validate := true;
end;

destructor TTreeParserDOMBase.destroy;
begin
  fparser.free;
  inherited destroy;
end;

function TTreeParserDOMBase.import(dom: TDOMDocument): TTreeDocument;
var doc: TTreeDocument;
  namespaces: TNamespaceList;
  function getNamespace(const url, prefix: string): INamespace;
  begin
    if namespaces.hasNamespacePrefix(prefix, result) then
      if result.getURL = url then exit;
    result := TNamespace.create(url, prefix);
    namespaces.add(result);
  end;

  procedure importNode(parent: TTreeNode; node: TDOMNode);
    function name(n: TDOMNode): string;
    begin
      if n.LocalName <>'' then result := UTF8Encode(n.LocalName)
      else result := UTF8Encode(n.NodeName);
    end;

  var
    i: Integer;
    new: TTreeNode;
    nscount: Integer;
  begin
    nscount := namespaces.Count;
    if node is TDOMElement then begin
      new := TTreeNode.createElementPair(name(node));
      new.document := parent.document; //if we do not set it now, further children do not know their document
      if node.HasAttributes then
        for i := 0 to node.Attributes.Length - 1 do begin
          new.addAttribute(name(node.Attributes[i]), UTF8Encode(node.Attributes[i].NodeValue));
          if (node.Attributes[i].NamespaceURI <> '') and (node.Attributes[i].NodeName <> 'xmlns') then
            new.attributes.Items[new.attributes.count - 1].namespace := getNamespace(UTF8Encode(node.Attributes[i].NamespaceURI), UTF8Encode(node.Attributes[i].Prefix));
        end;
      for i := 0 to node.ChildNodes.Count - 1 do
        importNode(new, node.ChildNodes[i]);
    end else begin
      if (node is TDOMText) or (node is TDOMCDATASection) then new := TTreeNode.create(tetText, UTF8Encode(node.NodeValue))
      else if node is TDOMComment then new := TTreeNode.create(tetComment, UTF8Encode(node.NodeValue))
      else if node is TDOMProcessingInstruction then begin
        new := TTreeNode.create(tetProcessingInstruction, UTF8Encode(node.NodeName));
        new.addAttribute('', UTF8Encode(node.NodeValue));
      end else exit;
    end;

    if node.NamespaceURI <> '' then
      new.namespace := getNamespace(UTF8Encode(node.NamespaceURI), UTF8Encode(node.Prefix));


    parent.addChild(new);
    namespaces.DeleteFrom(nscount);
  end;
var i: Integer;
  temp: TTreeNode;
  offset: Integer;
  a: TTreeAttribute;
begin
  namespaces:= TNamespaceList.Create;
  doc := TTreeDocument.create(self);
  doc.baseURI:=dom.baseURI;
  doc.documentURI:=dom.baseURI;
  doc.document := doc;

  doc.reverse := TTreeNode.create(tetClose);
  doc.reverse.reverse := doc;
  doc.next := doc.reverse;
  doc.next.previous := doc;
  doc.reverse.document := doc;

  for i := 0 to dom.ChildNodes.Count - 1 do
    importNode(doc, dom.ChildNodes[i]);

  temp := doc;
  offset := 1;
  while temp <> nil do begin
    temp.offset := offset;
    offset += 1;
    if temp.attributes <> nil then begin
      for a in temp.attributes do begin
        a.offset := offset;
        offset += 1;
      end;
    end;
    temp := temp.next;
  end;

  FTrees.Add(doc);
  FCurrentTree := doc;

  namespaces.free;
  result := doc;
end;

function TTreeParserDOMBase.parseDOM(const document: String; const uri: string): TTreeDocument;
var
  temp: TXMLDocument;
  source: TXMLInputSource;
begin
  Parser.Options.ExpandEntities := true;
  Parser.Options.PreserveWhitespace := not trimText;
  Parser.Options.IgnoreComments := not readComments;

  source:=TXMLInputSource.Create(document);
  try
    try
      Parser.Parse(source,temp);// TStringStream.Create(document)), temp);
      result := import(temp);
      result.baseURI:=uri;
      result.documentURI:=uri;
      temp.Free;
    finally
      source.free;
    end;
  except
    on e: EXMLReadError do raise ETreeParseException.Create(e.Message);
  end;
end;

function TTreeParserDOM.parseTree(html: string; uri: string; contentType: string): TTreeDocument;
begin
  Result:=parseDOM(html, uri);
end;
end.

