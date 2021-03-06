{$IFNDEF MSDOS}
{$I DEFINES.INC}
{$ENDIF}
{

Copyright 2007 Jakob Dangarden

 This file is part of Usurper.

    Usurper is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    Usurper is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Usurper; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
}


unit WantedSc; {Usurper - Wanted Hall, Posters and information concerning
                the wanted people}

interface

function Empty_WantedSlot: longint;

procedure Most_Wanted(cm: char);

implementation

uses
  Init, Cms, Jakob,
  News, Online, Various2,
  File_Io;

const
  max = 50; {if you change this you should also change max in BOUNTY.PAS}

var
  money: array [1..max] of ^longint;
  Name:  array [1..max] of ^s70;
  level: array [1..max] of ^byte;
  ai:    array [1..max] of ^char;

function Empty_WantedSlot: longint;
var q:    longint;
  kuvert: wantedrec;
  grepp:  boolean;
  tempdat1, tempdat2: Udate;
begin

  {find deletad post in wanted file}

  grepp := False;
  empty_wantedslot := 1;
  tempdat1 := fix_date(todays_date);

  for q := 1 to fs(FsWanted) do
  begin
    load_wanted(Fload, kuvert, q);

    {checking if wanted poster is old and can be discarded}
    if kuvert.collected = False then
    begin
      tempdat2 := fix_date(kuvert.date);
      if days_between(tempdat1, tempdat2) > config.maxwanted then
      begin
        kuvert.collected := True;
      end;
    end;

    if kuvert.collected = True then
    begin
      empty_wantedslot := q;
      grepp := True;
      break;
    end;
  end;

  if not grepp then
  begin
    empty_wantedslot := fs(FsWanted) + 1;
  end;

end;

procedure Sort_Wanteds;
var
  k, gap: integer;
  j, xx:  longint;
  i:      word;
  cr, yy: byte;
  found:  boolean;
  zz:     s70;
  vv:     char;
  wanted: wantedrec;

begin

  cr := 0;

  for i := 1 to fs(FsWanted) do
  begin
    load_wanted(Fload, wanted, i);

    found := False;
    if (wanted.Name <> '') and (not wanted.collected) then
    begin
      {finns denne efterlyste redan lagrad?}
      if cr > 0 then
      begin
        for j := 1 to cr do
        begin
          if Name[j]^ = wanted.Name then
          begin
            if money[j]^ <= 1900000000 then
            begin
              money[j]^ := money[j]^ + wanted.gold;
              level[j]^ := wanted.level;
            end;
            found := True;
            break;
          end;
        end;
      end;

      if found = False then
      begin
        Inc(cr);
        money[cr]^ := wanted.gold;
        Name[cr]^ := wanted.Name;
        level[cr]^ := wanted.level;
        ai[cr]^ := wanted.ai2;
      end;
    end;
  end;

  gap := max div 2;
  while gap > 0 do
  begin
    for i := (gap + 1) to max do
    begin
      j := i - gap;
      while (j > 0) do
      begin
        k := j + gap;
        if money[j]^ >= money[k]^ then
        begin
          j := 0;
        end else
        begin
          xx := money[j]^;
          zz := Name[j]^;
          yy := level[j]^;
          vv := ai[j]^;

          money[j]^ := money[k]^;
          Name[j]^ := Name[k]^;
          level[j]^ := level[k]^;
          ai[j]^ := ai[k]^;

          money[k]^ := xx;
          Name[k]^ := zz;
          level[k]^ := yy;
          ai[k]^ := vv;

          j := j - gap;
        end;
      end;
    end;
    gap := gap div 2;
  end;

end;

procedure Most_Wanted;
var
  j:       longint;
  s:       s70;
  i:       integer;
  pl0:     ^userrec;
  justval: byte;
  x:       integer;
  Lines, counter: byte;

begin

  {exit if wanted file doesn''t exist}
  if not f_exists(global_wwfile) then
  begin
    exit;
  end;

  {init pointer vars}
  for i := 1 to max do
  begin
    new(money[i]);
    money[i]^ := 0;

    new(Name[i]);
    Name[i]^ := emptystr;

    new(level[i]);

    new(ai[i]);
    ai[i]^ := 'C';

  end;
  new(pl0);


  case cm of
    'S': begin {external MOST WANTED list requested}

               {sort}
      SORT_WANTEDS;

      if (Name[1]^ <> '') and (money[1]^ > 0) then
      begin
        {news-paper}
        newsy(True,
          'Most Wanted',
          ' ' + uplc + Name[1]^ + 's' + config.textcol1 + ' life is worth ' + uyellow + commastr(money[1]^) +
          config.textcol1 + ' ' + many_money(money[1]^) + '!',
          '',
          '',
          '',
          '',
          '',
          '',
          '',
          '');

      end;

    end;
    'M': begin {internal top 50 MOST WANTED list requested}
      clearscreen;
      crlf;
      d(15, 'MOST WANTED CHARACTERS  ** TOP ' + commastr(max) + ' **');
      crlf;
      d(5, '#   Character            Worth     Level   Status');

      {sort}
      SORT_WANTEDS;

      Lines := 3;
      counter := 0;
      for i := 1 to max do
      begin
        if (Name[i]^ <> '') then
        begin
          {#}
          Inc(counter);
          s := commastr(counter);

          case length(s) of
            1: s := s + '   ';
            2: s := s + '  ';
            3: s := s + ' ';
          end;

          sd(15, s);

          {name}
          justval := 16;
          sd(12, ljust(Name[i]^, justval));
          s := commastr(money[i]^);
          x := length(s);
          if x < 11 then
          begin
            x := 11 - x;
            s := mkstring(x, ' ') + s;
          end;
          justval := 12;
          sd(14, ljust(s, justval));

          x := 0;
          {find players real level}
          if ai[i]^ = 'C' then
          begin
            for j := 1 to fs(FsNpc) do
            begin
              load_character(pl0^, 2, j);
              if pl0^.name2 = Name[i]^ then
              begin
                x := pl0^.level;
                break;
              end;
            end;
          end;

          if x = 0 then
          begin
            for j := 1 to fs(FsPlayer) do
            begin
              load_character(pl0^, 1, j);
              if pl0^.name2 = Name[i]^ then
              begin
                x := pl0^.level;
                break;
              end;
            end;
          end;

          {level}
          if x = 0 then
          begin
            x := level[i]^;
          end;
          sd(7, rjust(commastr(x), 8));

          {status}
          justval := 15;
          sd(config.textcolor, '   ');
          if is_online(pl0^.name2, online_player) then
          begin
            d(14, ljust('Online', justval));
          end else
          if (pl0^.location = offloc_prison) and (pl0^.hps > 0) then
          begin
            d(9, ljust('Prison', justval));
          end else
          if (pl0^.location = offloc_home) and (pl0^.hps > 0) then
          begin
            d(5, ljust('Home', justval));
          end else
          if (pl0^.location = offloc_beggarwall) and (pl0^.hps > 0) then
          begin
            d(5, ljust('Beggars Wall', justval));
          end else
          if (pl0^.location = offloc_dormitory) and (pl0^.hps > 0) then
          begin
            d(10, ljust('Dormitory', justval));
          end else
          if (pl0^.location in [offloc_innroom1..offloc_innroom4]) and (pl0^.hps > 0) then
          begin
            d(5, ljust('The Inn', justval));
          end else
          if (pl0^.location = offloc_castle) and (pl0^.hps > 0) then
          begin
            d(5, ljust('The Castle', justval));
          end else
          if pl0^.hps > 0 then
          begin
            d(15, ljust('Alive', justval));
          end else
          if pl0^.hps = -9000 then
          begin
            d(12, ljust('Drugged', justval));
          end else
          if pl0^.hps < 1 then
          begin
            d(12, ljust('Dead', justval));
          end;

          {should we pause the listing}
          Inc(Lines);
          if Lines > global_screenlines - 2 then
          begin
            Lines := 0;
            if confirm('Continue', 'Y') = False then
            begin
              break;
            end;
          end;

        end else
        begin
          break;
        end;
      end; {for i:= .end.}
    end;
  end;

  {dispose pointer vars}
  for i := 1 to max do
  begin
    dispose(money[i]);
    dispose(Name[i]);
    dispose(level[i]);
    dispose(ai[i]);
  end;
  dispose(pl0);

end; {Most_Wanted *end*}

end. {Unit WantedSc .end.}
