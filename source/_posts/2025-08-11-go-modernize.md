---
title: 现代化你的 Go 代码
date: 2025-08-08 17:10
created:
  - 2025-08-08
tags:
  - golang
  - lint
---

> [!note] TL; DR
> `go run golang.org/x/tools/gopls/internal/analysis/modernize/cmd/modernize@latest -test --fix ./...`
> 1. 自动使用现代化语法简化 Go 代码
> 2. 目前无法和 golangci-lint 集成，只能这么用 

https://github.com/golang/tools/tree/master/gopls/internal/analysis/modernize/testdata/src

## efaceany: replace interface{} by the 'any' type added in go1.18.


<table>
<thead><tr><th>Old</th><th>New</th></tr></thead>
<tbody>
<tr><td>

```go
var x interface{}
````

</td><td>

```go
var x any
```

</td></tr>
</tbody></table>

## stringsseq: replace Split in "for range strings.Split(...)" by go1.24's more efficient SplitSeq, or Fields with FieldSeq.


<table>
<thead><tr><th>Old</th><th>New</th></tr></thead>
<tbody>
<tr><td>

```go
for _, line := range strings.Split("", "") {
	println(line)
}

for _, line := range strings.Fields("") {
	println(line)
}
````

</td><td>

```go
for line := range strings.SplitSeq("", "") {
	println(line)
}

for line := range strings.FieldsSeq("") { 
	println(line)
}
```

</td></tr>
</tbody></table>

## mapsloop: replace a loop around an m[k]=v map update by a call to one of the Collect, Copy, Clone, or Insert functions from the maps package, added in go1.21.


<table>
<thead><tr><th>Old</th><th>New</th></tr></thead>
<tbody>
<tr><td>

```go
	for key, value := range src {
		dst[key] = value
	}
````

</td><td>

```go
	maps.Copy(dst, src)

	maps.Insert(dst, src)
```

</td></tr>
</tbody></table>

## minmax: replace an if/else conditional assignment by a call to the built-in min or max functions added in go1.21.


<table>
<thead><tr><th>Old</th><th>New</th></tr></thead>
<tbody>
<tr><td>

```go
	x := a 
	if a < b { 
		x = b
	}
````

</td><td>

```go
	 x := max(a, b)
```

</td></tr>
</tbody></table>

## rangeint: replace a 3-clause "for i := 0; i < n; i++" loop by "for i := range n", added in go1.22.


<table>
<thead><tr><th>Old</th><th>New</th></tr></thead>
<tbody>
<tr><td>

```go
	for i := 0; i < 10; i++ { 
		println(i)
	}
````

</td><td>

```go
	for i := range 10 { 
		println(i)
	}
```

</td></tr>
</tbody></table>

## slicescontains: replace 'for i, elem := range s { if elem == needle { ...; break }' by a call to slices.Contains, added in go1.21.

<table>
<thead><tr><th>Old</th><th>New</th></tr></thead>
<tbody>
<tr><td>

```go
	for i := range slice {
		if slice[i] == needle {
			println("found")
			 break
		}
	}
````

</td><td>

```go
	if slices.Contains(slice, needle) {
		println("found")
	}
```

</td></tr>
</tbody></table>

## slicesdelete: replace append(s[:i], s[i+1]...) by slices.Delete(s, i, i+1), added in go1.21.


<table>
<thead><tr><th>Old</th><th>New</th></tr></thead>
<tbody>
<tr><td>

```go
	test = append(test[:i], test[i+1:]...)
````

</td><td>

```go
	test = slices.Delete(test, i, i+1)
```

</td></tr>
</tbody></table>
