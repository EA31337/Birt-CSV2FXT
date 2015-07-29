/*
    Copyright (C) 2009-2012 Cristi Dumitrescu <birt@eareview.net>
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
*/

#include "stdafx.h"
#include "CsvReader.h"

bool CsvReadLine(CsvFile * f);

CsvFile * __stdcall CsvOpen(wchar_t * name, int delimiter) {
	FILE * fd;
	if (_wfopen_s(&fd, name, L"rb") == 0) {
		CsvFile *f = new CsvFile;
		f->fd = fd;
		f->bufPtr = 0;
		f->delimiter = delimiter;
		CsvReadLine(f); // fill the buffer
		return f;
	}
	return (CsvFile*)-1;
}

bool CsvReadLine(CsvFile * f) {
	memset(f->lineBuffer, 0, LINE_BUFFER_SIZE);
	f->bufPtr = 0;
	if (!fgets(f->lineBuffer, LINE_BUFFER_SIZE, f->fd)) {
		return false;
	}
	return true;
}

wchar_t * __stdcall CsvReadString(CsvFile * f) {
	memset(f->wstringBuffer, 0, 2 * STRING_BUFFER_SIZE);
	if (f->lineBuffer[f->bufPtr] == 0 ||
		f->lineBuffer[f->bufPtr] == '\r' ||
		f->lineBuffer[f->bufPtr] == '\n') {
		if (!CsvReadLine(f)) {
			// end of file
			return f->wstringBuffer;
		}
	}
	int i = 0;
	while (i < STRING_BUFFER_SIZE - 1 && f->bufPtr < LINE_BUFFER_SIZE) {
		char readchar = f->lineBuffer[f->bufPtr];
		f->bufPtr++;
		if (readchar == f->delimiter) {
			break;
		}
		if (readchar == 0 || readchar == '\r' || readchar == '\n') {
			f->bufPtr--;
			break;
		}
		wchar_t wreadchar = readchar;
		f->wstringBuffer[i] = readchar;
		i++;
	}
	return f->wstringBuffer;
}

double __stdcall CsvReadDouble(CsvFile * f) {
	CsvReadString(f);
	double result = 0;
	swscanf_s(f->wstringBuffer, L"%lf", &result);
	return result;
}

int __stdcall CsvIsLineEnding(CsvFile * f) {
	if (f->lineBuffer[f->bufPtr] == 0 ||
		f->lineBuffer[f->bufPtr] == '\r' ||
		f->lineBuffer[f->bufPtr] == '\n') {
		return 1;
	}
	return 0;
}

int __stdcall CsvIsEnding(CsvFile * f) {
	if (feof(f->fd)) {
		return 1;
	}
	return 0;
}

int __stdcall CsvClose(CsvFile * f) {
	if (fclose(f->fd) == 0) {
		delete f;
		return 1;
	}
	return 0;
}

int __stdcall CsvSeek(CsvFile * f, int offset, int origin) {
	if (_fseeki64(f->fd, offset, origin) == 0) {
		CsvReadLine(f);
		return 1;
	}
	return 0;
}
