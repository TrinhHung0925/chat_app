/// One page of a newest-first list. Pass [nextBefore] back to load the next page.
class PageModel<T> {
  final List<T> items;
  final int? nextBefore;

  const PageModel(this.items, this.nextBefore);

  bool get hasMore => nextBefore != null;
}
